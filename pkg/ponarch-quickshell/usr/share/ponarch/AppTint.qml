pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Warna glass mengikuti aplikasi yang sedang dibuka: diambil dari warna dominan ikon aplikasinya.
// Hanya bekerja saat jendela aktif berganti (tanpa polling); hasil disimpan per aplikasi.
Singleton {
    id: root

    property color tint: "#14161f"
    property bool ready: false
    property string cls: ""
    property var cache: ({})
    property string pending: ""

    function touch() { }

    function iconFor(c) {
        const names = [c, c.toLowerCase(), c.toLowerCase().replace(/\s+/g, "-"), c.toLowerCase().split(".").pop()]
        for (let i = 0; i < names.length; i++) {
            if (!names[i]) continue
            const p = Quickshell.iconPath(names[i], true)
            if (p) return p.charAt(0) === "/" ? p : ""
        }
        return ""
    }

    function setClass(c) {
        cls = c
        if (c === "") { ready = false; return }
        if (cache[c] !== undefined) {
            if (cache[c]) { tint = cache[c]; ready = true } else ready = false
            return
        }
        const p = iconFor(c)
        if (p === "") { cache[c] = null; ready = false; return }
        pending = c
        grab.command = ["sh", "-c", "if command -v magick >/dev/null 2>&1; then IM=magick; else IM=convert; fi; $IM \"$1[0]\" -background none -alpha remove -resize 64x64 -colors 10 -depth 8 -format %c histogram:info:", "sh", p]
        grab.running = true
    }

    Connections {
        target: Hyprland
        enabled: Settings.glassTint === "app"
        function onRawEvent(event) {
            if (event.name === "activewindow") root.setClass((event.data.split(",")[0] || "").trim())
        }
    }

    Process {
        id: grab
        stdout: StdioCollector {
            onStreamFinished: {
                const r = Wall.analyze(text)
                const c = root.pending
                if (!r || !r.vivid) { root.cache[c] = null; if (root.cls === c) root.ready = false; return }
                root.cache[c] = r.tint
                if (root.cls === c) { root.tint = r.tint; root.ready = true }
            }
        }
    }
}
