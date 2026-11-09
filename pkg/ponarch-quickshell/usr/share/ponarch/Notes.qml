pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias items: store.items       // [{ text }]

    function title(t) {
        const l = (t || "").split("\n")[0].trim()
        return l !== "" ? l : "(kosong)"
    }
    function add() { store.items = [{ text: "" }].concat(store.items) }
    function update(i, t) {
        if (i < 0 || i >= store.items.length) return
        const c = store.items.slice()
        c[i] = { text: t }
        store.items = c
    }
    function remove(i) {
        const c = store.items.slice()
        c.splice(i, 1)
        store.items = c
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/ponarch/notes.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }
        adapter: JsonAdapter {
            id: store
            property var items: []
        }
    }
}
