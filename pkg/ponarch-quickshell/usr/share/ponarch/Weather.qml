pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var cur: null            // { temperature_2m, apparent_temperature, relative_humidity_2m, weather_code, wind_speed_10m }
    property var days: []             // [{ day, code, max, min }]
    property double fetchedAt: 0
    property string fetchedKey: ""
    property string pendingKey: ""
    property bool asked: false
    readonly property bool loading: proc.running

    function ensure() {
        Loc.ensure()
        if (!proc.running && (Date.now() - fetchedAt > 15 * 60 * 1000 || (Loc.settled && fetchedKey !== Loc.key))) refresh()
    }
    function refresh() {
        if (proc.running) return
        Loc.ensure()
        if (!Loc.settled) { asked = true; return }
        pendingKey = Loc.key
        proc.command = ["curl", "-s", "--max-time", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + Loc.lat + "&longitude=" + Loc.lon
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=5"]
        proc.running = true
    }

    function icon(c) {
        if (c <= 1) return "weather-sun"
        if (c <= 3 || c === 45 || c === 48) return "weather-cloud"
        if (c >= 71 && c <= 77) return "weather-snow"
        if (c >= 95) return "weather-storm"
        return "weather-rain"
    }
    function desc(c) {
        if (c === 0) return "Cerah"
        if (c <= 2) return "Cerah berawan"
        if (c === 3) return "Berawan"
        if (c === 45 || c === 48) return "Berkabut"
        if (c >= 51 && c <= 57) return "Gerimis"
        if (c >= 61 && c <= 67) return "Hujan"
        if (c >= 71 && c <= 77) return "Salju"
        if (c >= 80 && c <= 82) return "Hujan lebat"
        if (c >= 95) return "Badai petir"
        return "—"
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    root.cur = j.current
                    root.days = j.daily.time.map((t, i) => ({
                        day: t,
                        code: j.daily.weather_code[i],
                        max: Math.round(j.daily.temperature_2m_max[i]),
                        min: Math.round(j.daily.temperature_2m_min[i])
                    }))
                    root.fetchedAt = Date.now()
                    root.fetchedKey = root.pendingKey
                } catch (e) { }
            }
        }
    }

    Connections {
        target: Loc
        function onLocated() {
            if (root.asked || (root.fetchedAt > 0 && root.fetchedKey !== Loc.key)) { root.asked = false; root.refresh() }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: Settings.leftSlot === "weather" || Settings.rightSlot === "weather"
        onTriggered: root.refresh()
    }
}
