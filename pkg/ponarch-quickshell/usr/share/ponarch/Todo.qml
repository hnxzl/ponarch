pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias items: store.items
    readonly property int openCount: items.filter(x => !x.done).length

    function add(t) {
        t = (t || "").trim()
        if (t === "") return
        store.items = store.items.concat([{ text: t, done: false }])
    }
    function toggle(i) {
        const c = store.items.slice()
        c[i] = { text: c[i].text, done: !c[i].done }
        store.items = c
    }
    function remove(i) {
        const c = store.items.slice()
        c.splice(i, 1)
        store.items = c
    }
    function clearDone() { store.items = store.items.filter(x => !x.done) }

    FileView {
        path: Quickshell.env("HOME") + "/.config/ponarch/todo.json"
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
