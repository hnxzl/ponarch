pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// HUD volume/kecerahan di notch tertutup.
Singleton {
    id: root

    property string kind: "vol"       // vol | bri
    property real value: 0
    property bool muted: false
    property bool shown: false
    property bool armed: false

    property string briPath: ""
    property int briMax: 1
    property int briLast: -1

    function touch() { }

    function flash(k, v, m) {
        if (!armed || !Settings.hud) return
        kind = k
        value = Math.max(0, Math.min(1, v))
        muted = m === true
        shown = true
        hideTimer.restart()
    }

    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }
    Timer { interval: 3000; running: true; onTriggered: root.armed = true }

    Process {
        running: Settings.hud
        command: ["sh", "-c", "d=$(ls -d /sys/class/backlight/* 2>/dev/null | head -1); [ -n \"$d\" ] && echo \"$d/brightness $(cat $d/max_brightness)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ")
                if (p.length === 2) { root.briPath = p[0]; root.briMax = Math.max(1, parseInt(p[1])) }
            }
        }
    }
    FileView {
        id: bv
        path: root.briPath
        onLoaded: {
            const v = parseInt(text())
            if (isNaN(v)) return
            if (root.briLast >= 0 && v !== root.briLast) root.flash("bri", v / root.briMax, false)
            root.briLast = v
        }
    }
    Timer {
        interval: 2000
        repeat: true
        running: Settings.hud && root.briPath !== ""
        onTriggered: bv.reload()
    }
}
