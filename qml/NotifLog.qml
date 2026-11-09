pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Riwayat notifikasi: mendengarkan panggilan Notify di D-Bus (dbus-monitor), tidak mengganggu swaync/mako/dunst.
Singleton {
    id: root

    property alias items: store.items       // [{ app, summary, body, t }]
    property string blk: ""
    property bool collecting: false
    signal arrived(string app, string summary, string body, string icon, string de, string img)

    function touch() { }
    function clear() { store.items = [] }

    // mode mendengarkan (daemon lain): popup + riwayat
    function push(a, s, b, ic, de, img) {
        arrived(a, s, b, ic || "", de || "", img || "")
        record(a, s, b, ic, de, img)
    }
    // hanya simpan ke riwayat
    function record(a, s, b, ic, de, img) {
        if (!Settings.notifLog) return
        const keep = (img || "").indexOf("image://") === 0 ? "" : (img || "")   // gambar inline bersifat sementara
        const n = [{ app: a, summary: s, body: b, icon: ic || "", de: de || "", img: keep, t: Date.now() }].concat(store.items)
        store.items = n.slice(0, 100)
    }

    function finish(text) {
        const cut = text.search(/\n {3}array \[/)
        const head = cut >= 0 ? text.slice(0, cut) : text
        const hints = cut >= 0 ? text.slice(cut) : ""
        const parts = head.replace(/\n$/, "").split(/\n(?=\s+(?:string|uint32|int32|array|byte|boolean) )/)
        const strs = []
        for (let i = 0; i < parts.length; i++) {
            const m = /^\s*string "([\s\S]*)"\s*$/.exec(parts[i])
            if (m) strs.push(m[1])
        }
        if (strs.length < 3) return
        const hint = k => {
            const m = new RegExp('string "' + k + '"\\s+variant\\s+string "([^"]*)"').exec(hints)
            return m ? m[1] : ""
        }
        // strs: [app_name, app_icon, summary, body]
        push(strs[0], strs[2], strs.length > 3 ? strs[3] : "", strs[1],
             hint("desktop-entry"), hint("image-path") || hint("image_path"))
    }

    function feed(line) {
        if (/^(method call|method return|signal|error)/.test(line)) {
            collecting = line.indexOf("method call") === 0 && line.indexOf("member=Notify") >= 0
            blk = ""
            return
        }
        if (!collecting) return
        if (/^ {3}int32 /.test(line)) {      // argumen terakhir (expire_timeout)
            collecting = false
            finish(blk)
            return
        }
        blk += line + "\n"
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/ponarch/notifs.json"
        watchChanges: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }
        adapter: JsonAdapter {
            id: store
            property var items: []
        }
    }

    Process {
        running: !Settings.notifDaemon && (Settings.notifLog || Settings.notifToast)
        command: ["dbus-monitor", "--session", "interface='org.freedesktop.Notifications',member='Notify'"]
        stdout: SplitParser { onRead: data => root.feed(data) }
    }
}
