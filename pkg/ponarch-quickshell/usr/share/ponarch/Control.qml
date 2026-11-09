import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

ColumnLayout {
    id: ctl
    spacing: 8

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    readonly property bool micMuted: !!source && !!source.audio && source.audio.muted
    readonly property bool btOn: !!Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled

    // quick toggles
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Tile { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Wi-Fi"; active: Sys.wifiOn
               onClicked: Sys.toggleWifi() }
        Tile { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Bluetooth"; active: ctl.btOn
               onClicked: { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled } }
        Tile { Layout.fillWidth: true; Layout.preferredWidth: 10; label: ctl.micMuted ? "Mic off" : "Mic"; active: !ctl.micMuted
               onClicked: { if (ctl.source && ctl.source.audio) ctl.source.audio.muted = !ctl.source.audio.muted } }
        Tile { Layout.fillWidth: true; Layout.preferredWidth: 10
               label: Sys.profile === "performance" ? "Perform" : Sys.profile === "power-saver" ? "Saver" : "Balanced"
               active: Sys.profile === "performance"
               onClicked: Sys.cycleProfile() }
    }

    // launchers (editable in ~/.config/ponarch/settings.json)
    GridLayout {
        Layout.fillWidth: true
        columns: 5
        columnSpacing: 6
        rowSpacing: 6
        Repeater {
            model: Settings.launchers
            Tile {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 10
                label: modelData.label
                onClicked: Sys.run(modelData.cmd)
            }
        }
    }

    // sliders side by side
    RowLayout {
        Layout.fillWidth: true
        spacing: 14
        Slider {
            Layout.fillWidth: true
            Layout.preferredWidth: 10
            label: "Audio"
            value: ctl.sink && ctl.sink.audio ? ctl.sink.audio.volume : 0
            onMoved: v => { if (ctl.sink && ctl.sink.audio) ctl.sink.audio.volume = v }
        }
        Slider {
            Layout.fillWidth: true
            Layout.preferredWidth: 10
            label: "Light"
            value: Sys.brightness
            onMoved: v => Sys.setBrightness(v)
        }
    }

    Item { Layout.fillHeight: true }

    // power
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        PowerButton { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Lock"; confirm: false
                      cmd: ["sh", "-c", "loginctl lock-session"] }
        PowerButton { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Sleep"; cmd: ["systemctl", "suspend"] }
        PowerButton { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Restart"; cmd: ["systemctl", "reboot"] }
        PowerButton { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Logout"; cmd: ["hyprctl", "dispatch", "exit"] }
        PowerButton { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Shutdown"; cmd: ["systemctl", "poweroff"] }
    }
}
