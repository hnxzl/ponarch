pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Lirik berwaktu dari LRCLIB (aktif kalau Settings.lyrics = true).
Singleton {
    id: root

    property var lines: []
    property string state: "idle"      // idle | loading | none | ok
    property string key: ""

    readonly property var player: Media.player
    readonly property string trackKey: player ? (player.trackArtist + "|" + player.trackTitle) : ""
    readonly property bool wanted: Settings.lyrics && !!player && trackKey !== "|"
    readonly property int index: {
        const p = player ? player.position : 0
        let i = -1
        for (let k = 0; k < lines.length; k++) {
            if (lines[k].t <= p) i = k
            else break
        }
        return i
    }
    readonly property string current: index >= 0 && index < lines.length ? lines[index].text : ""

    onTrackKeyChanged: fetch()
    onWantedChanged: {
        if (!wanted) { lines = []; key = ""; state = "idle" }
        fetch()
    }

    function parse(str) {
        const out = []
        const rows = (str || "").split("\n")
        const re = /^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/
        for (let i = 0; i < rows.length; i++) {
            const m = re.exec(rows[i])
            if (m) out.push({ t: parseInt(m[1]) * 60 + parseFloat(m[2]), text: m[3] })
        }
        return out
    }

    function fetch() {
        if (!wanted || trackKey === key) return
        if (getProc.running || searchProc.running) { retry.restart(); return }
        key = trackKey
        lines = []
        state = "loading"
        getProc.command = ["curl", "-s", "--max-time", "10", "-G", "https://lrclib.net/api/get",
            "--data-urlencode", "artist_name=" + player.trackArtist,
            "--data-urlencode", "track_name=" + player.trackTitle,
            "--data-urlencode", "duration=" + Math.round(player.length)]
        getProc.running = true
    }
    function done(rows) {
        if (key !== trackKey) { key = ""; retry.restart(); return }   // lagu sudah ganti saat mencari
        lines = rows
        state = rows.length > 0 ? "ok" : "none"
    }
    // proses lama bisa masih "running" saat hasilnya sudah diterima, jadi ulangi sebentar lagi
    Timer { id: retry; interval: 250; onTriggered: root.fetch() }

    Process {
        id: getProc
        stdout: StdioCollector {
            onStreamFinished: {
                let rows = []
                try { rows = root.parse(JSON.parse(text).syncedLyrics) } catch (e) { }
                if (rows.length > 0 || !root.player || root.key !== root.trackKey) { root.done(rows); return }
                searchProc.command = ["curl", "-s", "--max-time", "10", "-G", "https://lrclib.net/api/search",
                    "--data-urlencode", "artist_name=" + root.player.trackArtist,
                    "--data-urlencode", "track_name=" + root.player.trackTitle]
                searchProc.running = true
            }
        }
    }
    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                let rows = []
                try {
                    const arr = JSON.parse(text)
                    for (let i = 0; i < arr.length && rows.length === 0; i++) rows = root.parse(arr[i].syncedLyrics)
                } catch (e) { }
                root.done(rows)
            }
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: root.wanted && Media.playing && root.lines.length > 0 && (UI.expanded || Settings.lyricsClosed)
        onTriggered: root.player.positionChanged()
    }
}
