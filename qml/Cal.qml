pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Kalender dari link iCal (.ics): Google Calendar, Outlook, dll.
// Mendukung RRULE dasar (DAILY/WEEKLY(+BYDAY)/MONTHLY/YEARLY, INTERVAL, COUNT, UNTIL). TZID dianggap waktu lokal.
Singleton {
    id: root

    property var events: []            // [{ start, end, title, loc, allDay, cal }]
    property double fetchedAt: 0
    property var notified: ({})
    readonly property bool loading: proc.running || gproc.running || gadd.running
    property bool gOn: false           // Google Calendar API aktif (sudah `ponarch gcal`)
    property string gError: ""
    readonly property string gScript: Quickshell.shellDir + "/gcal.py"
    readonly property bool configured: gOn || (Settings.calendars && Settings.calendars.length > 0)

    function touch() { }

    function ensure() {
        if (!proc.running && Date.now() - fetchedAt > 20 * 60 * 1000) refresh()
    }
    function refresh() {
        if (proc.running || gproc.running) return
        if (gOn) { gproc.command = ["python3", gScript, "list", "14"]; gproc.running = true; return }
        const cals = Settings.calendars || []
        if (cals.length === 0) { events = []; return }
        const urls = cals.map(c => c.url.replace(/^webcal:/, "https:"))
        proc.command = ["sh", "-c", "for u in \"$@\"; do curl -sL --max-time 20 \"$u\"; echo; echo '@@PONARCH-END@@'; done", "sh"].concat(urls)
        proc.running = true
    }
    function addCal(url) {
        url = (url || "").trim()
        if (url === "") return
        url = url.replace(/^webcal/i, "https")
        Settings.calendars = [{ name: "Kalender", url: url }]    // satu link saja
        fetchedAt = 0
        refresh()
    }
    // tambah acara ke Google Calendar; start/end = "YYYY-MM-DDTHH:MM" waktu lokal
    function addEvent(title, start, end, allDay) {
        title = (title || "").trim()
        if (!gOn || title === "" || gadd.running) return
        gError = ""
        gadd.command = ["python3", gScript, "add", title, start, end, allDay ? "1" : "0"]
        gadd.running = true
    }
    function removeCal(i) {
        const c = (Settings.calendars || []).slice()
        c.splice(i, 1)
        Settings.calendars = c
        fetchedAt = 0
        refresh()
    }

    function pdate(v) {
        let m = /^(\d{4})(\d\d)(\d\d)$/.exec(v)
        if (m) return { ms: new Date(+m[1], +m[2] - 1, +m[3]).getTime(), allDay: true }
        m = /^(\d{4})(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)(Z?)$/.exec(v)
        if (m) {
            const ms = m[7] === "Z" ? Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6])
                                    : new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]).getTime()
            return { ms: ms, allDay: false }
        }
        return null
    }
    function unesc(s) { return (s || "").replace(/\\n/gi, " ").replace(/\\,/g, ",").replace(/\\;/g, ";").replace(/\\\\/g, "\\") }

    function expand(ev, from, to) {
        const rule = {}
        ev.rrule.split(";").forEach(p => { const i = p.indexOf("="); if (i > 0) rule[p.slice(0, i)] = p.slice(i + 1) })
        const dur = ev.end - ev.start
        const interval = Math.max(1, parseInt(rule.INTERVAL || "1"))
        const max = rule.COUNT ? parseInt(rule.COUNT) : 100000
        let until = Infinity
        if (rule.UNTIL) { const u = pdate(rule.UNTIL.replace(/Z$/, "") + (rule.UNTIL.length > 8 && rule.UNTIL.slice(-1) !== "Z" ? "" : (rule.UNTIL.length > 8 ? "Z" : ""))); if (u) until = u.ms }
        const base = new Date(ev.start)
        const res = []
        let n = 0
        const freq = rule.FREQ

        if (freq === "WEEKLY" && rule.BYDAY) {
            const map = { SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6 }
            const days = rule.BYDAY.split(",").map(s => map[s.slice(-2)]).filter(x => x !== undefined).sort()
            for (let w = 0; w < 700 && n < max; w += interval) {
                let weekStartMs = 0
                for (let k = 0; k < days.length; k++) {
                    const d = new Date(base.getFullYear(), base.getMonth(), base.getDate() - base.getDay() + w * 7 + days[k],
                                       base.getHours(), base.getMinutes(), base.getSeconds())
                    const s = d.getTime()
                    weekStartMs = s
                    if (s < ev.start) continue
                    if (s > until) return res
                    n++
                    if (n > max) return res
                    if (s + dur >= from && s <= to) res.push(s)
                }
                if (weekStartMs > to) break
            }
            return res
        }
        if (freq !== "DAILY" && freq !== "WEEKLY" && freq !== "MONTHLY" && freq !== "YEARLY") return [ev.start]
        for (let i = 0; i < 4000 && n < max; i += interval) {
            const d = new Date(ev.start)
            if (freq === "DAILY") d.setDate(d.getDate() + i)
            else if (freq === "WEEKLY") d.setDate(d.getDate() + 7 * i)
            else if (freq === "MONTHLY") d.setMonth(d.getMonth() + i)
            else d.setFullYear(d.getFullYear() + i)
            const s = d.getTime()
            if (s > until || s > to) break
            n++
            if (s + dur >= from) res.push(s)
        }
        return res
    }

    function parseIcs(text, name, from, to) {
        const src = text.replace(/\r/g, "").replace(/\n[ \t]/g, "")
        const rows = src.split("\n")
        const out = []
        let ev = null
        for (let r = 0; r < rows.length; r++) {
            const row = rows[r]
            if (row === "BEGIN:VEVENT") { ev = { allDay: false }; continue }
            if (row === "END:VEVENT") {
                if (ev && ev.start !== undefined && !ev.cancelled) {
                    if (ev.end === undefined) ev.end = ev.start + (ev.allDay ? 86400000 : 3600000)
                    if (ev.rrule) {
                        const dur = ev.end - ev.start
                        expand(ev, from, to).forEach(s => out.push({ start: s, end: s + dur, title: ev.title || "(tanpa judul)", loc: ev.loc || "", allDay: ev.allDay, cal: name }))
                    } else if (ev.end >= from && ev.start <= to) {
                        out.push({ start: ev.start, end: ev.end, title: ev.title || "(tanpa judul)", loc: ev.loc || "", allDay: ev.allDay, cal: name })
                    }
                }
                ev = null
                continue
            }
            if (!ev) continue
            const c = row.indexOf(":")
            if (c < 0) continue
            const key = row.slice(0, c).split(";")[0]
            const val = row.slice(c + 1)
            if (key === "DTSTART") { const d = pdate(val); if (d) { ev.start = d.ms; ev.allDay = d.allDay } }
            else if (key === "DTEND") { const d = pdate(val); if (d) ev.end = d.ms }
            else if (key === "SUMMARY") ev.title = unesc(val)
            else if (key === "LOCATION") ev.loc = unesc(val)
            else if (key === "RRULE") ev.rrule = val
            else if (key === "STATUS" && val === "CANCELLED") ev.cancelled = true
        }
        return out
    }

    function nextText(now) {
        const t = now.getTime()
        for (let i = 0; i < events.length; i++) {
            const e = events[i]
            if (e.allDay || e.end < t) continue
            const m = Math.round((e.start - t) / 60000)
            if (m <= 0) return "Now " + e.title
            return (m >= 60 ? Math.floor(m / 60) + "j" : m + "m") + " " + e.title
        }
        return "—"
    }

    // cukup cek berkas kredensial (tidak perlu menjalankan python hanya untuk status)
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/ponarch/google.json"
        onLoaded: { root.gOn = text().indexOf("refresh_token") >= 0; if (root.gOn) root.refresh() }
        onLoadFailed: root.gOn = false
    }
    Process {
        id: gproc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    if (Array.isArray(j)) { root.events = j; root.gError = "" } else root.gError = j.error || "?"
                } catch (e) { root.gError = "?" }
                root.fetchedAt = Date.now()
            }
        }
    }
    Process {
        id: gadd
        stdout: StdioCollector {
            onStreamFinished: {
                let ok = false
                try { const j = JSON.parse(text); ok = j.ok === true; if (!ok) root.gError = j.error || "?" } catch (e) { root.gError = "?" }
                if (ok) { root.gError = ""; root.fetchedAt = 0; root.refresh() }
            }
        }
    }
    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                const from = Date.now() - 6 * 3600000
                const to = Date.now() + 14 * 86400000
                const parts = text.split("@@PONARCH-END@@")
                const cals = Settings.calendars || []
                let all = []
                for (let i = 0; i < cals.length && i < parts.length; i++)
                    all = all.concat(root.parseIcs(parts[i], cals[i].name, from, to))
                all.sort((a, b) => a.start - b.start)
                root.events = all
                root.fetchedAt = Date.now()
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: root.configured
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    // pengingat rapat
    Timer {
        interval: 60000
        repeat: true
        running: root.configured
        onTriggered: {
            const now = Date.now()
            const n = Object.assign({}, root.notified)
            for (let i = 0; i < root.events.length; i++) {
                const e = root.events[i]
                const m = (e.start - now) / 60000
                const k = e.start + e.title
                if (!e.allDay && m > 0 && m <= Settings.calRemind && !n[k]) {
                    n[k] = true
                    Quickshell.execDetached(["notify-send", "-a", "Ponarch", e.title,
                                             "Mulai " + Qt.formatTime(new Date(e.start), "HH:mm") + (e.loc ? " · " + e.loc : "")])
                }
            }
            root.notified = n
        }
    }
}
