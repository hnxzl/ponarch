pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shelf dan Drop Actions: seret file ke notch, lalu simpan / zip / ekstrak / konversi / salin / pindah / buka / buang.
Singleton {
    id: root

    property alias items: store.items       // [path]

    function pathsFrom(urls) {
        const out = []
        for (let i = 0; i < urls.length; i++) {
            const s = urls[i].toString()
            if (s.indexOf("file://") === 0) out.push(decodeURIComponent(s.replace(/^file:\/\//, "")))
        }
        return out
    }
    function nameOf(p) { return p.split("/").pop() }
    function add(paths) {
        const s = store.items.slice()
        paths.forEach(p => { if (s.indexOf(p) < 0) s.push(p) })
        store.items = s
    }
    function remove(i) { const s = store.items.slice(); s.splice(i, 1); store.items = s }
    function clear() { store.items = [] }

    readonly property var scripts: ({
        zip: "out=\"$(dirname \"$1\")/ponarch-$(date +%H%M%S).zip\"; zip -rq \"$out\" \"$@\" && notify-send -a Ponarch 'Zip selesai' \"$out\" || notify-send -a Ponarch 'Zip gagal' 'pasang paket zip'",
        extract: "for f in \"$@\"; do bsdtar -xf \"$f\" -C \"$(dirname \"$f\")\"; done; notify-send -a Ponarch 'Ekstrak selesai' \"$#\"' arsip'",
        convert: "for f in \"$@\"; do magick \"$f\" \"${f%.*}.png\" 2>/dev/null || convert \"$f\" \"${f%.*}.png\"; done; notify-send -a Ponarch 'Konversi ke PNG selesai' \"$#\"' file'",
        copy: "d=$(zenity --file-selection --directory 2>/dev/null || kdialog --getexistingdirectory \"$HOME\" 2>/dev/null) || exit 0; cp -r -- \"$@\" \"$d\"/ && notify-send -a Ponarch 'Disalin ke' \"$d\"",
        move: "d=$(zenity --file-selection --directory 2>/dev/null || kdialog --getexistingdirectory \"$HOME\" 2>/dev/null) || exit 0; mv -- \"$@\" \"$d\"/ && notify-send -a Ponarch 'Dipindah ke' \"$d\"",
        open: "for f in \"$@\"; do xdg-open \"$f\"; done",
        trash: "gio trash \"$@\" 2>/dev/null || trash-put \"$@\"; notify-send -a Ponarch 'Dibuang ke sampah' \"$#\"' file'",
        share: "pgrep -x localsend_app >/dev/null || pgrep -x localsend >/dev/null || ponarch localsend; notify-send -a Ponarch 'Share' 'Seret file dari Shelf ke jendela LocalSend'"
    })

    function run(action, paths) {
        if (!paths || paths.length === 0) return
        if (action === "shelf") { add(paths); return }
        if (action === "share") add(paths)
        const sc = scripts[action]
        if (!sc) return
        Quickshell.execDetached(["sh", "-c", sc, "sh"].concat(paths))
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/ponarch/shelf.json"
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
