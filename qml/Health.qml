pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Pengingat kesehatan: minum, gerak, napas, jeda mata 20-20-20. Hitungan harian tersimpan.
Singleton {
    id: root

    readonly property int waterGoal: 8
    readonly property int moveGoal: 6
    readonly property int breathGoal: 5
    property alias water: store.water
    property alias move: store.move
    property alias breath: store.breath

    property bool breathing: false
    property int bsec: 0
    readonly property string phase: { const c = bsec % 14; return c < 4 ? "Tarik napas…" : c < 8 ? "Tahan…" : "Hembuskan…" }

    function touch() { }
    function notify(t, b) { Quickshell.execDetached(["notify-send", "-a", "Ponarch", t, b]) }

    function norm() {
        const t = Qt.formatDate(new Date(), "yyyy-MM-dd")
        if (store.date !== t) { store.date = t; store.water = 0; store.move = 0; store.breath = 0 }
    }
    function addWater(d) { norm(); store.water = Math.max(0, store.water + d) }
    function addMove() { norm(); store.move += 1 }
    function startBreath() { breathing = true; bsec = 0 }
    function stopBreath() { breathing = false; bsec = 0 }

    Timer {
        interval: 1000
        repeat: true
        running: root.breathing
        onTriggered: {
            root.bsec += 1
            if (root.bsec >= 56) {
                root.breathing = false
                root.bsec = 0
                root.norm()
                store.breath += 1
                root.notify("Latihan napas selesai", "Bagus. Lanjutkan harimu.")
            }
        }
    }
    Timer {
        interval: 20 * 60 * 1000
        repeat: true
        running: Settings.eyeBreak
        onTriggered: root.notify("Jeda mata 20-20-20", "Lihat sesuatu sejauh 6 meter selama 20 detik.")
    }
    Timer {
        interval: Math.max(1, Settings.waterEvery) * 60 * 1000
        repeat: true
        running: Settings.waterEvery > 0
        onTriggered: root.notify("Waktunya minum", "Segelas air dulu.")
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/ponarch/health.json"
        watchChanges: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }
        adapter: JsonAdapter {
            id: store
            property string date: ""
            property int water: 0
            property int move: 0
            property int breath: 0
        }
    }
}
