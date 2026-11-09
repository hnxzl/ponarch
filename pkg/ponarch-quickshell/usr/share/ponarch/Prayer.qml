pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var times: ({})          // { Fajr: "04:12", Dhuhr: ..., Asr: ..., Maghrib: ..., Isha: ... }
    property string fetchedFor: ""
    property string pendingFor: ""
    property bool asked: false
    readonly property bool loading: proc.running
    readonly property var names: [["Fajr", "Subuh"], ["Dhuhr", "Dzuhur"], ["Asr", "Ashar"], ["Maghrib", "Maghrib"], ["Isha", "Isya"]]

    // jadwal diambil per tanggal + lokasi laptop (Loc), jadi ikut berubah kalau pindah kota
    function ensure() {
        Loc.ensure()
        if (!Loc.settled) { asked = true; return }
        const today = Qt.formatDate(new Date(), "dd-MM-yyyy")
        const k = today + "|" + Loc.key
        if (proc.running || k === fetchedFor) return
        pendingFor = k
        proc.command = ["curl", "-s", "--max-time", "10",
            "https://api.aladhan.com/v1/timings/" + today + "?latitude=" + Loc.lat
            + "&longitude=" + Loc.lon + "&method=" + Settings.prayerMethod]
        proc.running = true
    }
    Connections {
        target: Loc
        function onLocated() { if (root.asked || root.fetchedFor !== "") { root.asked = false; root.ensure() } }
    }
    Timer { id: again; interval: 400; onTriggered: root.ensure() }

    function minutesOf(hhmm) {
        const p = hhmm.split(":")
        return parseInt(p[0]) * 60 + parseInt(p[1])
    }

    // returns { key, label, time, left } (left = minutes until it starts) or null
    function nextInfo(now) {
        if (!times.Fajr) return null
        const cur = now.getHours() * 60 + now.getMinutes()
        for (let i = 0; i < names.length; i++) {
            const t = minutesOf(times[names[i][0]])
            if (t > cur) return { key: names[i][0], label: names[i][1], time: times[names[i][0]], left: t - cur }
        }
        return { key: "Fajr", label: "Subuh", time: times.Fajr, left: 1440 - cur + minutesOf(times.Fajr) }
    }
    function fmtLeft(l) { return l >= 60 ? Math.floor(l / 60) + "j " + (l % 60) + "m" : l + "m" }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const t = JSON.parse(text).data.timings
                    root.times = {
                        Fajr: t.Fajr.slice(0, 5), Dhuhr: t.Dhuhr.slice(0, 5), Asr: t.Asr.slice(0, 5),
                        Maghrib: t.Maghrib.slice(0, 5), Isha: t.Isha.slice(0, 5)
                    }
                    root.fetchedFor = root.pendingFor
                    if (!root.pendingFor.endsWith("|" + Loc.key)) again.restart()   // lokasi berubah saat mengambil
                } catch (e) { }
            }
        }
    }

    Timer {
        interval: 60 * 60 * 1000
        repeat: true
        running: Settings.leftSlot === "prayer" || Settings.rightSlot === "prayer"
        onTriggered: root.ensure()
    }
}
