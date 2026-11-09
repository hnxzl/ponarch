pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var levels: [0, 0, 0, 0, 0]
    property bool ok: false
    readonly property bool wanted: Settings.cava && Media.playing && !UI.expanded

    Process {
        running: root.wanted
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        stdout: SplitParser {
            onRead: data => {
                const a = data.split(";").filter(s => s !== "").map(Number)
                if (a.length >= 5) {
                    root.levels = a.slice(0, 5).map(v => Math.min(1, v / 100))
                    root.ok = true
                }
            }
        }
        onRunningChanged: { if (!running) root.ok = false }
    }
}
