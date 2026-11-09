import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

ColumnLayout {
    id: sysTab
    spacing: 8

    readonly property var bat: UPower.displayDevice
    readonly property bool batOn: !!bat && bat.isPresent
    readonly property bool charging: !!bat && bat.state === UPowerDeviceState.Charging

    function gb(kb) { return (kb / 1048576).toFixed(1) }
    function dur(sec) { const m = Math.round(sec / 60); return m >= 60 ? Math.floor(m / 60) + "j " + (m % 60) + "m" : m + "m" }
    function up(sec) { const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60); return (d > 0 ? d + "h " : "") + h + "j " + m + "m" }
    function batText() {
        if (!batOn) return ""
        let t = Math.round(bat.percentage * 100) + "%"
        if (bat.energyCapacity > 0) t += "  ·  " + bat.energy.toFixed(1) + " / " + bat.energyCapacity.toFixed(1) + " Wh"
        if (bat.changeRate > 0) t += "  ·  " + bat.changeRate.toFixed(1) + " W"
        const left = charging ? bat.timeToFull : bat.timeToEmpty
        if (left > 0) t += "  ·  " + dur(left) + (charging ? " penuh" : " habis")
        return t
    }
    // baris detail: [label, teks]
    readonly property var rows: [
        ["CPU", Sys.cpu + "%  ·  load " + Sys.load.toFixed(2) + "  ·  " + Sys.cores + " core"],
        ["RAM", gb(Sys.memUsed) + " / " + gb(Sys.memTotal) + " GB  (" + Sys.mem + "%)"],
        ["Swap", Sys.swapTotal > 0 ? gb(Sys.swapUsed) + " / " + gb(Sys.swapTotal) + " GB" : "tidak aktif"],
        ["Disk /", gb(Sys.diskUsed) + " / " + gb(Sys.diskTotal) + " GB  (" + Sys.disk + "%)"],
        ["Suhu", Sys.temp + " °C"],
        ["Uptime", up(Sys.uptime)]
    ]

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            StatBar { Layout.fillWidth: true; visible: !Settings.sysDetail; label: "CPU"; value: Sys.cpu / 100; valueText: Sys.cpu + "%" }
            StatBar { Layout.fillWidth: true; visible: !Settings.sysDetail; label: "RAM"; value: Sys.mem / 100; valueText: Sys.mem + "%" }
            StatBar { Layout.fillWidth: true; visible: !Settings.sysDetail; label: "Disk"; value: Sys.disk / 100; valueText: Sys.disk + "%" }
            StatBar { Layout.fillWidth: true; visible: !Settings.sysDetail; label: "Temp"; value: Sys.temp / 100; valueText: Sys.temp + "°C" }
            StatBar {
                Layout.fillWidth: true
                visible: !Settings.sysDetail && sysTab.batOn
                label: "Bat"
                value: sysTab.bat ? sysTab.bat.percentage : 0
                valueText: Math.round((sysTab.bat ? sysTab.bat.percentage : 0) * 100) + "%"
            }

            // mode detail
            Repeater {
                model: Settings.sysDetail ? sysTab.rows : []
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8
                    Text { Layout.preferredWidth: 50; color: Settings.dim; font.pixelSize: 11; text: modelData[0] }
                    Text { Layout.fillWidth: true; elide: Text.ElideRight; color: "white"; font.pixelSize: 12; text: modelData[1] }
                }
            }
            RowLayout {
                visible: Settings.sysDetail && sysTab.batOn
                Layout.fillWidth: true
                spacing: 8
                Text { Layout.preferredWidth: 50; color: Settings.dim; font.pixelSize: 11; text: "Bat" }
                Text { Layout.fillWidth: true; elide: Text.ElideRight; color: "white"; font.pixelSize: 12; text: sysTab.batText() }
            }

            // widget buatan sendiri (Settings.widgets)
            Repeater {
                model: Settings.widgets
                CustomWidget {
                    required property var modelData
                    Layout.fillWidth: true
                    label: modelData.label ?? ""
                    exec: modelData.exec ?? ""
                    pollSeconds: modelData.interval ?? 10
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    Tile {
        Layout.fillWidth: true
        implicitHeight: 26
        label: Settings.sysDetail ? "Mode: Detail  ·  ketuk untuk Bar" : "Mode: Bar  ·  ketuk untuk Detail"
        onClicked: Settings.sysDetail = !Settings.sysDetail
    }
}
