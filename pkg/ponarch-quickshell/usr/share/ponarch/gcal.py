#!/usr/bin/env python3
"""Google Calendar untuk Ponarch: auth sekali, lalu list/add acara lewat Calendar API.

  gcal.py auth            login sekali (butuh OAuth client "Desktop app" milikmu)
  gcal.py status          cetak {"configured": true/false}
  gcal.py list [HARI]     acara dari 6 jam lalu sampai HARI ke depan (JSON)
  gcal.py add JUDUL MULAI SELESAI [seharian]   MULAI/SELESAI = YYYY-MM-DDTHH:MM (waktu lokal)

Rahasia disimpan di ~/.config/ponarch/google.json (izin 600); token akses sementara di ~/.cache/ponarch.
Output selalu JSON di stdout; kesalahan -> {"error": "..."}.
"""
import datetime as dt
import http.server
import json
import os
import secrets
import socket
import sys
import urllib.error
import urllib.parse
import urllib.request

CONF = os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "ponarch", "google.json")
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "ponarch", "gtoken.json")
API = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
SCOPE = "https://www.googleapis.com/auth/calendar.events"
TOKEN_URL = "https://oauth2.googleapis.com/token"
AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"


def write_private(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(data, f)


def http_json(url, data=None, headers=None, method=None):
    body = None
    h = dict(headers or {})
    if data is not None:
        if h.get("Content-Type") == "application/json":
            body = json.dumps(data).encode()
        else:
            body = urllib.parse.urlencode(data).encode()
            h.setdefault("Content-Type", "application/x-www-form-urlencoded")
    req = urllib.request.Request(url, data=body, headers=h, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        try:
            detail = json.loads(e.read().decode())
            msg = detail.get("error_description") or detail.get("error", {}).get("message") or detail.get("error")
        except Exception:
            msg = e.reason
        raise RuntimeError(f"{e.code}: {msg}")


def load_conf():
    with open(CONF) as f:
        c = json.load(f)
    if not c.get("refresh_token"):
        raise RuntimeError("belum login: jalankan `ponarch gcal`")
    return c


def access_token():
    now = dt.datetime.now().timestamp()
    try:
        with open(CACHE) as f:
            c = json.load(f)
        if c.get("expires", 0) > now + 60:
            return c["token"]
    except Exception:
        pass
    conf = load_conf()
    r = http_json(TOKEN_URL, {
        "client_id": conf["client_id"], "client_secret": conf["client_secret"],
        "refresh_token": conf["refresh_token"], "grant_type": "refresh_token"})
    write_private(CACHE, {"token": r["access_token"], "expires": now + int(r.get("expires_in", 3600))})
    return r["access_token"]


def auth_headers():
    return {"Authorization": "Bearer " + access_token()}


def to_ms(s, end=False):
    """dateTime RFC3339 atau date (YYYY-MM-DD) -> (ms epoch, allDay)."""
    if "T" in s:
        return int(dt.datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp() * 1000), False
    d = dt.date.fromisoformat(s)
    return int(dt.datetime(d.year, d.month, d.day).timestamp() * 1000), True


def normalize(items):
    out = []
    for it in items:
        if it.get("status") == "cancelled":
            continue
        s, e = it.get("start", {}), it.get("end", {})
        sv = s.get("dateTime") or s.get("date")
        ev = e.get("dateTime") or e.get("date") or sv
        if not sv:
            continue
        start, all_day = to_ms(sv)
        end, _ = to_ms(ev)
        out.append({"id": it.get("id", ""), "title": it.get("summary") or "(tanpa judul)", "start": start,
                    "end": end, "allDay": all_day, "loc": it.get("location", ""), "cal": "Google"})
    out.sort(key=lambda x: x["start"])
    return out


def cmd_list(days=14):
    now = dt.datetime.now(dt.timezone.utc)
    q = urllib.parse.urlencode({
        "timeMin": (now - dt.timedelta(hours=6)).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "timeMax": (now + dt.timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "singleEvents": "true", "orderBy": "startTime", "maxResults": "60"})
    r = http_json(API + "?" + q, headers=auth_headers())
    return normalize(r.get("items", []))


def local_iso(s):
    d = dt.datetime.strptime(s, "%Y-%m-%dT%H:%M").astimezone()
    return d.isoformat(timespec="seconds")


def build_event(title, start, end, all_day):
    if all_day:
        d = dt.datetime.strptime(start[:10], "%Y-%m-%d").date()
        return {"summary": title, "start": {"date": d.isoformat()}, "end": {"date": (d + dt.timedelta(days=1)).isoformat()}}
    return {"summary": title, "start": {"dateTime": local_iso(start)}, "end": {"dateTime": local_iso(end)}}


def cmd_add(title, start, end, all_day=False):
    r = http_json(API, data=build_event(title, start, end, all_day),
                  headers={**auth_headers(), "Content-Type": "application/json"}, method="POST")
    return {"ok": True, "id": r.get("id", "")}


class _Handler(http.server.BaseHTTPRequestHandler):
    result = {}

    def do_GET(self):
        q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        type(self).result = {k: v[0] for k, v in q.items()}
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write("Selesai. Tab ini boleh ditutup.".encode())

    def log_message(self, *a):
        pass


def cmd_auth():
    print("Ponarch + Google Calendar (sekali saja).")
    print("Buat dulu OAuth client bertipe 'Desktop app' di console.cloud.google.com (lihat README).")
    cid = input("Client ID: ").strip()
    secret = input("Client secret: ").strip()
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    redirect = f"http://127.0.0.1:{port}"
    state = secrets.token_urlsafe(16)
    url = AUTH_URL + "?" + urllib.parse.urlencode({
        "client_id": cid, "redirect_uri": redirect, "response_type": "code", "scope": SCOPE,
        "access_type": "offline", "prompt": "consent", "state": state})
    server = http.server.HTTPServer(("127.0.0.1", port), _Handler)
    server.timeout = 300
    print("\nBuka link ini di browser dan setujui akses:\n\n" + url + "\n")
    try:
        import webbrowser
        webbrowser.open(url)
    except Exception:
        pass
    server.handle_request()
    res = _Handler.result
    if res.get("state") != state or "code" not in res:
        raise RuntimeError("login dibatalkan atau tidak valid: " + str(res.get("error", "")))
    r = http_json(TOKEN_URL, {"code": res["code"], "client_id": cid, "client_secret": secret,
                              "redirect_uri": redirect, "grant_type": "authorization_code"})
    if not r.get("refresh_token"):
        raise RuntimeError("Google tidak memberi refresh token; coba lagi")
    write_private(CONF, {"client_id": cid, "client_secret": secret, "refresh_token": r["refresh_token"]})
    print("Berhasil. Tersimpan di " + CONF)
    return None


def main(argv):
    if not argv:
        print(__doc__)
        return 0
    c = argv[0]
    try:
        if c == "auth":
            cmd_auth()
            return 0
        if c == "status":
            ok = os.path.exists(CONF) and bool(json.load(open(CONF)).get("refresh_token"))
            print(json.dumps({"configured": ok}))
            return 0
        if c == "list":
            print(json.dumps(cmd_list(int(argv[1]) if len(argv) > 1 else 14)))
            return 0
        if c == "add":
            print(json.dumps(cmd_add(argv[1], argv[2], argv[3], len(argv) > 4 and argv[4] == "1")))
            return 0
        print(json.dumps({"error": "perintah tidak dikenal"}))
        return 1
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
