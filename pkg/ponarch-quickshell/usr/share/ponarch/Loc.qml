pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Lokasi laptop lewat IP publik (akurasi tingkat kota; VPN akan menggeser hasilnya).
// Kalau Settings.autoLocation mati atau gagal: pakai Settings.city/lat/lon.
Singleton {
    id: root

    signal located()

    property bool have: false
    property bool done: false
    property real aLat: 0
    property real aLon: 0
    property string aCity: ""
    property double fetchedAt: 0
    property int step: 0

    readonly property bool settled: !Settings.autoLocation || done
    readonly property bool auto: Settings.autoLocation && have
    readonly property real lat: auto ? aLat : Settings.lat
    readonly property real lon: auto ? aLon : Settings.lon
    readonly property string city: auto ? aCity : Settings.city
    readonly property string key: lat.toFixed(1) + "," + lon.toFixed(1)

    function ensure() {
        if (!Settings.autoLocation || proc.running || next.running) return
        if (Date.now() - fetchedAt < 10 * 60 * 1000) return
        fetchedAt = Date.now()
        step = 0
        run()
    }
    function run() {
        proc.command = ["curl", "-s", "--max-time", "8", step === 0 ? "https://ipwho.is/" : "https://ipapi.co/json/"]
        proc.running = true
    }
    // ---- lokasi manual: link Google Maps, "lat, lon", atau nama tempat (OpenStreetMap Nominatim) ----
    property string msg: ""
    property string qmode: ""

    function coords(t) {
        const m = /@(-?\d+\.\d+),(-?\d+\.\d+)/.exec(t) || /!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)/.exec(t)
                  || /[?&](?:q|ll|query|destination)=(-?\d+\.\d+)(?:,|%2C)\s*(-?\d+\.\d+)/.exec(t)
                  || /^(-?\d+(?:\.\d+)?)\s*[,;\s]\s*(-?\d+(?:\.\d+)?)$/.exec(t)
        if (!m) return null
        const la = Number(m[1]), lo = Number(m[2])
        return Math.abs(la) > 90 || Math.abs(lo) > 180 ? null : [la, lo]
    }
    function placeName(t) {
        const m = /\/place\/([^\/@?]+)/.exec(t)
        if (!m) return ""
        try { return decodeURIComponent(m[1].replace(/\+/g, " ")).split(",")[0] } catch (e) { return "" }
    }
    function apply(la, lo, name) {
        Settings.autoLocation = false
        Settings.lat = la
        Settings.lon = lo
        Settings.city = name !== "" ? name : "Lokasi pilihan"
        msg = ""
        done = true
        located()
        if (name === "") { qmode = "reverse"; runQ(["-G", "https://nominatim.openstreetmap.org/reverse", "-d", "format=jsonv2&zoom=10&lat=" + la + "&lon=" + lo]) }
    }
    function runQ(args) {
        q.command = ["curl", "-s", "--max-time", "10", "-A", "ponarch-quickshell"].concat(args)
        qnext.restart()
    }
    function setManual(t) {
        t = (t || "").trim()
        if (t === "" || q.running || qnext.running) return
        const c = coords(t)
        if (c) { apply(c[0], c[1], placeName(t)); return }
        if (/^https?:\/\//.test(t)) {
            msg = "Membuka link…"; qmode = "resolve"
            runQ(["-L", "-o", "/dev/null", "-w", "%{url_effective}", t])
            return
        }
        msg = "Mencari…"; qmode = "search"
        runQ(["-G", "https://nominatim.openstreetmap.org/search", "--data-urlencode", "q=" + t, "-d", "format=json&limit=1"])
    }
    function qdone(text) {
        if (qmode === "resolve") {
            const c = coords(text)
            if (c) apply(c[0], c[1], placeName(text)); else msg = "Link tidak dikenali"
        } else if (qmode === "search") {
            try {
                const j = JSON.parse(text)[0]
                if (j) { apply(Number(j.lat), Number(j.lon), (j.name || j.display_name || "").split(",")[0].trim()); return }
            } catch (e) { }
            msg = "Tempat tidak ketemu"
        } else if (qmode === "reverse") {
            try {
                const a = JSON.parse(text).address || {}
                const n = a.city || a.town || a.village || a.county || a.state || ""
                if (n !== "" && !Settings.autoLocation) Settings.city = n
            } catch (e) { }
        }
    }
    Process {
        id: q
        stdout: StdioCollector { onStreamFinished: root.qdone(text) }
    }
    Timer { id: qnext; interval: 300; onTriggered: q.running = true }

    function finish(ok) {
        if (!ok && step === 0) { step = 1; next.restart(); return }
        done = true
        located()
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                let ok = false
                try {
                    const j = JSON.parse(text)
                    const la = Number(j.latitude), lo = Number(j.longitude)
                    if (j.success !== false && j.error !== true && isFinite(la) && isFinite(lo) && (la !== 0 || lo !== 0)) {
                        root.aLat = la
                        root.aLon = lo
                        root.aCity = j.city || j.region || ""
                        root.have = true
                        ok = true
                    }
                } catch (e) { }
                root.finish(ok)
            }
        }
    }
    // jeda singkat supaya proses sebelumnya benar-benar selesai sebelum yang berikutnya
    Timer { id: next; interval: 300; onTriggered: root.run() }
}
