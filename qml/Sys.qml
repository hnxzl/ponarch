pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property real brightness: 0
    property bool wifiOn: false
    property string profile: "balanced"
    property int cpu: 0
    property int mem: 0
    property int disk: 0
    property int temp: 0
    // detail (KB untuk memori/disk)
    property real memUsed: 0
    property real memTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property real diskUsed: 0
    property real diskTotal: 0
    property real load: 0
    property int cores: 0
    property real uptime: 0

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

    function setBrightness(v) {
        root.brightness = v
        Quickshell.execDetached(["brightnessctl", "set", Math.max(1, Math.round(v * 100)) + "%"])
    }
    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"])
        root.wifiOn = !root.wifiOn
    }
    function cycleProfile() {
        const order = ["power-saver", "balanced", "performance"]
        const next = order[(order.indexOf(root.profile) + 1) % order.length]
        Quickshell.execDetached(["powerprofilesctl", "set", next])
        root.profile = next
    }

    onActiveChanged: {
        if (active) { briGet.running = true; wifiGet.running = true; profGet.running = true }
    }

    Process {
        id: briGet
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                if (p.length >= 4) root.brightness = parseInt(p[3]) / 100
            }
        }
    }
    Process {
        id: wifiGet
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: profGet
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") root.profile = text.trim() }
    }
    Process {
        id: statsProc
        command: ["sh", "-c",
            "c=$(top -bn2 -d0.5 | grep '^%Cpu' | tail -1 | awk '{printf \"%d\", 100-$8}'); " +
            "m=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf \"%d\",(t-a)*100/t}' /proc/meminfo); " +
            "d=$(df --output=pcent / | tail -1 | tr -dc 0-9); " +
            "t=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1); " +
            "mm=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print t-a, t}' /proc/meminfo); " +
            "sw=$(awk '/SwapTotal/{t=$2}/SwapFree/{f=$2}END{print t-f, t}' /proc/meminfo); " +
            "dd=$(df --output=used,size -BK / | tail -1 | tr -dc '0-9 ' | xargs); " +
            "l=$(cut -d' ' -f1 /proc/loadavg); n=$(nproc); u=$(cut -d. -f1 /proc/uptime); " +
            "echo \"$c $m $d $(( ${t:-0} / 1000 )) $mm $sw $dd $l $n $u\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/).map(Number)
                if (p.length === 13) {
                    root.cpu = p[0]; root.mem = p[1]; root.disk = p[2]; root.temp = p[3]
                    root.memUsed = p[4]; root.memTotal = p[5]; root.swapUsed = p[6]; root.swapTotal = p[7]
                    root.diskUsed = p[8]; root.diskTotal = p[9]; root.load = p[10]; root.cores = p[11]; root.uptime = p[12]
                }
            }
        }
    }
    Timer {
        running: root.active
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!statsProc.running) statsProc.running = true }
    }
}
