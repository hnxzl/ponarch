pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string mode: "focus"          // focus | short | long | timer | stopwatch
    property bool running: false
    property int remaining: Settings.focusMin * 60
    property int elapsed: 0
    property int timerMin: 10
    property int sessions: 0
    readonly property bool isWatch: mode === "stopwatch"
    readonly property int total: isWatch ? 0 : durationFor(mode)
    // 0..1 untuk cincin di sekeliling notch (stopwatch: 1 putaran per jam)
    readonly property real progress: isWatch ? (elapsed % 3600) / 3600
                                     : (total > 0 ? Math.max(0, Math.min(1, 1 - remaining / total)) : 0)
    readonly property bool ringOn: running || (!isWatch && remaining < total) || (isWatch && elapsed > 0)
    readonly property string label: fmt(isWatch ? elapsed : remaining)
    readonly property string modeName: mode === "focus" ? "Focus" : mode === "short" ? "Short break"
                                       : mode === "long" ? "Long break" : mode === "timer" ? "Timer" : "Stopwatch"

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function fmt(s) {
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), c = s % 60
        return (h > 0 ? h + ":" + pad(m) : pad(m)) + ":" + pad(c)
    }
    function durationFor(m) {
        if (m === "timer") return timerMin * 60
        return (m === "focus" ? Settings.focusMin : m === "short" ? Settings.shortMin : Settings.longMin) * 60
    }
    function setMode(m) {
        running = false
        mode = m
        remaining = durationFor(m)
        if (m === "stopwatch") elapsed = 0
    }
    function toggle() { running = !running }
    function reset() { running = false; remaining = durationFor(mode); elapsed = 0 }
    function adjustTimer(d) {
        if (mode !== "timer" || running) return
        timerMin = Math.max(1, Math.min(180, timerMin + d))
        remaining = timerMin * 60
    }
    function skip() {
        if (mode === "timer" || mode === "stopwatch") return
        advance()
    }
    function advance() {
        let next = "focus"
        if (mode === "focus") {
            sessions += 1
            next = sessions % 4 === 0 ? "long" : "short"
        }
        setMode(next)
    }
    function finish() {
        if (mode === "timer") {
            Quickshell.execDetached(["notify-send", "-a", "Ponarch", "Timer selesai", timerMin + " menit"])
            setMode("timer")
            return
        }
        const wasFocus = mode === "focus"
        Quickshell.execDetached(["notify-send", "-a", "Ponarch", wasFocus ? "Fokus selesai" : "Istirahat selesai",
                                 wasFocus ? "Saatnya istirahat." : "Kembali fokus."])
        advance()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.isWatch) { root.elapsed += 1; return }
            root.remaining -= 1
            if (root.remaining <= 0) root.finish()
        }
    }
}
