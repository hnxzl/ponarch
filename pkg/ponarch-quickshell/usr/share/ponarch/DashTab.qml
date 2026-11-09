import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

GridLayout {
    id: dash
    columns: 2
    columnSpacing: 8
    rowSpacing: 8
    property date now: new Date()

    Component.onCompleted: Weather.ensure()
    Timer { interval: 30000; repeat: true; running: true; onTriggered: dash.now = new Date() }

    // weather
    Rectangle {
        visible: Settings.weatherDashboard
        Layout.fillWidth: true; Layout.fillHeight: true
        Layout.preferredWidth: 1; Layout.preferredHeight: 1
        antialiasing: true; radius: 14; color: Settings.tile
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 10; spacing: 2
            Text { color: Settings.dim; font.pixelSize: 11; text: Loc.city }
            RowLayout {
                spacing: 8
                Icon { width: 28; height: 28; name: Weather.cur ? Weather.icon(Weather.cur.weather_code) : "weather-cloud" }
                Text { color: "white"; font.pixelSize: 26; font.bold: true; text: Weather.cur ? Math.round(Weather.cur.temperature_2m) + "°" : "—" }
            }
            Text { color: Settings.soft; font.pixelSize: 11; text: Weather.cur ? Weather.desc(Weather.cur.weather_code) : "" }
            Item { Layout.fillHeight: true }
        }
    }

    // quick toggles
    Rectangle {
        Layout.fillWidth: true; Layout.fillHeight: true
        Layout.preferredWidth: 1; Layout.preferredHeight: 1
        antialiasing: true; radius: 14; color: Settings.tile
        GridLayout {
            anchors.fill: parent; anchors.margins: 8
            columns: 2; columnSpacing: 6; rowSpacing: 6
            Tile { Layout.fillWidth: true; Layout.fillHeight: true; label: "Wi-Fi"; active: Sys.wifiOn; onClicked: Sys.toggleWifi() }
            Tile { Layout.fillWidth: true; Layout.fillHeight: true; label: "BT"
                   active: !!Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                   onClicked: { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled } }
            Tile { Layout.fillWidth: true; Layout.fillHeight: true; label: "Mata"; active: Settings.eyeBreak
                   onClicked: Settings.eyeBreak = !Settings.eyeBreak }
            Tile { Layout.fillWidth: true; Layout.fillHeight: true
                   label: Sys.profile === "performance" ? "Perform" : Sys.profile === "power-saver" ? "Saver" : "Balanced"
                   active: Sys.profile === "performance"; onClicked: Sys.cycleProfile() }
        }
    }

    // apps
    Rectangle {
        Layout.fillWidth: true; Layout.fillHeight: true
        Layout.preferredWidth: 1; Layout.preferredHeight: 1
        antialiasing: true; radius: 14; color: Settings.tile
        GridLayout {
            anchors.fill: parent; anchors.margins: 8
            columns: 3; columnSpacing: 6; rowSpacing: 6
            Repeater {
                model: (Settings.launchers || []).slice(0, 6)
                Tile {
                    required property var modelData
                    Layout.fillWidth: true; Layout.fillHeight: true
                    label: modelData.label
                    onClicked: Sys.run(modelData.cmd)
                }
            }
        }
    }

    // day progress
    Rectangle {
        Layout.fillWidth: true; Layout.fillHeight: true
        Layout.preferredWidth: 1; Layout.preferredHeight: 1
        antialiasing: true; radius: 14; color: Settings.tile
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 10; spacing: 4
            Text { color: "white"; font.pixelSize: 26; font.bold: true; text: Math.round(Day.dayFrac(dash.now) * 100) + "%" }
            Rectangle {
                Layout.fillWidth: true; height: 5; antialiasing: true; radius: 2.5; color: "#333333"
                Rectangle { height: parent.height; antialiasing: true; radius: 2.5; color: Settings.accentColor; width: parent.width * Day.dayFrac(dash.now) }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
