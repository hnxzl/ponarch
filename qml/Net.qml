pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Daftar Wi-Fi dan sambung lewat nmcli.
Singleton {
    id: root

    property var nets: []               // [{ ssid, signal, secure, active, saved }]
    readonly property bool loading: proc.running

    function ensure() { refresh() }
    function refresh() {
        if (proc.running) return
        proc.running = true
    }
    function rescan() {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"])
        refreshLater.restart()
    }
    function connect(ssid, pw) {
        const cmd = ["nmcli", "dev", "wifi", "connect", ssid]
        if (pw) cmd.push("password", pw)
        Quickshell.execDetached(cmd)
        refreshLater.restart()
    }
    function disconnect(ssid) {
        Quickshell.execDetached(["nmcli", "connection", "down", "id", ssid])
        refreshLater.restart()
    }

    function splitNm(line) {
        // nmcli -t memakai ":" sebagai pemisah dan "\:" untuk titik dua di dalam nilai
        return line.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"))
    }

    Timer { id: refreshLater; interval: 2500; onTriggered: root.refresh() }

    Process {
        id: proc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null; echo '@@SAVED@@'; nmcli -t -f NAME,TYPE connection show 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const halves = text.split("@@SAVED@@")
                const saved = {}
                ;(halves[1] || "").split("\n").forEach(l => {
                    if (l.trim() === "") return
                    const p = root.splitNm(l)
                    if (p.length >= 2 && p[1].indexOf("wireless") >= 0) saved[p[0]] = true
                })
                const best = {}
                ;(halves[0] || "").split("\n").forEach(l => {
                    if (l.trim() === "") return
                    const p = root.splitNm(l)
                    if (p.length < 4 || p[3] === "") return
                    const n = {
                        ssid: p[3],
                        signal: parseInt(p[1]) || 0,
                        secure: p[2] !== "" && p[2] !== "--",
                        active: p[0] === "*",
                        saved: !!saved[p[3]]
                    }
                    const o = best[n.ssid]
                    if (!o || n.active || (!o.active && n.signal > o.signal)) best[n.ssid] = n
                })
                const arr = Object.keys(best).map(k => best[k])
                arr.sort((a, b) => (b.active - a.active) || (b.signal - a.signal))
                root.nets = arr
            }
        }
    }
}
