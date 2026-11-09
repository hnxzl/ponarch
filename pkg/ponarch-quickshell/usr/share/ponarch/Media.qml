pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    // pemain terakhir yang dipakai tetap dipilih saat dijeda, supaya tidak loncat ke pemain lain.
    // Disimpan di objek biasa (bukan property) agar tidak membuat binding loop.
    readonly property var memo: ({ p: null })
    readonly property var player: {
        const list = Mpris.players.values
        const on = list.find(p => p.isPlaying)
        const r = on ?? (memo.p && list.includes(memo.p) ? memo.p
                         : (list.find(p => p.trackTitle !== "") ?? list[0] ?? null))
        if (r) memo.p = r
        return r
    }
    readonly property bool playing: !!player && player.isPlaying
}
