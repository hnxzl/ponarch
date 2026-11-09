pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Screen Time: waktu fokus per aplikasi (kelas jendela Hyprland), tersimpan per hari.
Singleton {
    id: root

    property string cur: ""
    property double since: Date.now()
    property var pend: ({})                 // detik yang belum ditulis ke file
    readonly property var apps: store.apps

    function touch() { }

    function accrue() {
        const now = Date.now()
        if (cur !== "") {
            const p = Object.assign({}, pend)
            p[cur] = (p[cur] || 0) + (now - since) / 1000
            pend = p
        }
        since = now
    }
    function persist() {
        accrue()
        const today = Qt.formatDate(new Date(), "yyyy-MM-dd")
        if (store.date === today && Object.keys(pend).length === 0) return     // tidak ada yang perlu ditulis
        let a = Object.assign({}, store.apps)
        if (store.date !== today) { store.date = today; a = {} }
        for (const k in pend) a[k] = Math.round((a[k] || 0) + pend[k])
        store.apps = a
        pend = {}
    }
    function switchTo(c) { accrue(); cur = c }
    function seconds(k) { return (store.apps[k] || 0) + (pend[k] || 0) }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow") root.switchTo((event.data.split(",")[0] || "").trim())
        }
    }
    Timer { interval: 180000; repeat: true; running: true; onTriggered: root.persist() }
    // simpan juga saat notch dibuka supaya tab Screen selalu akurat
    Connections { target: UI; function onExpandedChanged() { if (UI.expanded) root.persist() } }

    FileView {
        path: Quickshell.env("HOME") + "/.config/ponarch/screentime.json"
        watchChanges: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }
        adapter: JsonAdapter {
            id: store
            property string date: ""
            property var apps: ({})
        }
    }
}
