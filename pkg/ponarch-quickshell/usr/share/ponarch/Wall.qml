pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Warna dari wallpaper: aksen (warna paling hidup) dan tint glass (versi gelapnya).
Singleton {
    id: root

    property color accent: "#5b7cff"
    property color tint: "#14161f"
    property bool ready: false
    property string sig: ""
    property string file: ""

    readonly property bool wanted: Settings.accentFromWall || Settings.glassTint === "wallpaper"
    readonly property string path: Settings.wallpaper !== "" ? Settings.wallpaper
                                   : Quickshell.env("HOME") + "/.config/hypr/current_wallpaper"

    function touch() { }
    function check() {
        if (!wanted || probe.running || grab.running) return
        probe.running = true
    }
    onWantedChanged: check()
    Component.onCompleted: check()
    onPathChanged: { sig = ""; check() }

    function pick(text) {
        const r = analyze(text)
        if (!r) return false
        accent = r.accent
        tint = r.tint
        ready = true
        return true
    }

    // teks histogram ImageMagick -> { accent, tint } atau null
    function analyze(text) {
        const rows = []
        let total = 0
        text.split("\n").forEach(l => {
            const m = /^\s*(\d+):\s*\(\s*(\d+),\s*(\d+),\s*(\d+)/.exec(l)
            if (m) { rows.push({ n: +m[1], r: +m[2] / 255, g: +m[3] / 255, b: +m[4] / 255 }); total += +m[1] }
        })
        if (rows.length === 0 || total === 0) return null
        let best = null, bestScore = 0, top = rows[0]
        rows.forEach(c => {
            const mx = Math.max(c.r, c.g, c.b), mn = Math.min(c.r, c.g, c.b)
            const l = (mx + mn) / 2, d = mx - mn
            const s = d === 0 ? 0 : d / (1 - Math.abs(2 * l - 1))
            let h = 0
            if (d !== 0) {
                if (mx === c.r) h = ((c.g - c.b) / d) % 6
                else if (mx === c.g) h = (c.b - c.r) / d + 2
                else h = (c.r - c.g) / d + 4
                h = (h / 6 + 1) % 1
            }
            c.h = h; c.s = s; c.l = l
            if (c.n > top.n) top = c
            const score = Math.sqrt(c.n / total) * s * (1 - Math.abs(l - 0.5) * 1.2)
            if (s > 0.15 && score > bestScore) { bestScore = score; best = c }
        })
        const base = best || top
        const h = base.h
        const s = best ? Math.max(0.45, Math.min(0.85, base.s)) : 0.3
        return {
            accent: Qt.hsla(h, s, Math.max(0.55, Math.min(0.68, base.l < 0.4 ? 0.6 : base.l)), 1),
            tint: Qt.hsla(h, Math.min(0.4, base.s * 0.6 + 0.1), 0.12, 1),
            vivid: !!best
        }
    }

    Timer { interval: 30000; repeat: true; running: root.wanted; onTriggered: root.check() }
    Connections { target: UI; function onExpandedChanged() { if (UI.expanded) root.check() } }

    // path asli + waktu modifikasi: hanya hitung ulang saat wallpaper berganti
    Process {
        id: probe
        command: ["sh", "-c", "f=$(readlink -f \"$1\"); echo \"$f|$(stat -c %Y \"$f\" 2>/dev/null)\"", "sh", root.path]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                if (s === "" || s === root.sig) return
                root.sig = s
                root.file = s.split("|")[0]
                grab.running = true
            }
        }
    }
    Process {
        id: grab
        command: ["sh", "-c", "if command -v magick >/dev/null 2>&1; then IM=magick; else IM=convert; fi; $IM \"$1[0]\" -alpha off -resize 96x96 -colors 12 -depth 8 -format %c histogram:info:", "sh", root.file]
        stdout: StdioCollector { onStreamFinished: root.pick(text) }
    }
}
