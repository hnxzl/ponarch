pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Jangan Ganggu. Saat Ponarch jadi daemon notifikasi, statusnya milik Ponarch (Settings.dnd);
// kalau tidak, mengikuti swaync lewat swaync-client.
Singleton {
    id: root
    readonly property bool daemon: Settings.notifDaemon
    property bool sw: false
    property bool swKnown: false
    readonly property bool on: daemon ? Settings.dnd : sw
    readonly property bool known: daemon ? true : swKnown

    function touch() { }
    function toggle() {
        if (daemon) Settings.dnd = !Settings.dnd
        else Quickshell.execDetached(["swaync-client", "-d", "-sw"])
    }

    Process {
        id: sub
        running: !root.daemon
        command: ["swaync-client", "-s"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const j = JSON.parse(data)
                    if (j.dnd !== undefined) { root.sw = j.dnd === true; root.swKnown = true }
                } catch (e) { }
            }
        }
        onExited: { if (!root.daemon) retry.start() }
    }
    Timer { id: retry; interval: 5000; onTriggered: sub.running = !root.daemon }
}
