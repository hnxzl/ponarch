import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.UPower

// Isi sisi kiri/kanan notch tertutup.
// kind: none | workspaces | battery | date | pomodoro | prayer | weather | event
Item {
    id: s
    property string kind: "none"
    property date now: new Date()
    implicitWidth: 76
    implicitHeight: 28

    function wake() {
        if (kind === "weather") Weather.ensure()
        else if (kind === "prayer") Prayer.ensure()
        else if (kind === "event") Cal.ensure()
    }
    Component.onCompleted: wake()
    onKindChanged: wake()

    readonly property string txt: {
        switch (kind) {
        case "battery": {
            const b = UPower.displayDevice
            if (!b || !b.isPresent) return ""
            return Math.round(b.percentage * 100) + "%"
        }
        case "date": return Qt.formatDate(now, "ddd d")
        case "pomodoro": return Pomo.label
        case "prayer": {
            const n = Prayer.nextInfo(now)
            return n ? n.label + " " + Prayer.fmtLeft(n.left) : "…"
        }
        case "event": return Cal.nextText(now)
        case "weather":
            return Weather.cur ? Math.round(Weather.cur.temperature_2m) + "°" : "…"
        default: return ""
        }
    }

    Row {
        anchors.centerIn: parent
        visible: s.kind === "workspaces"
        spacing: 5
        Repeater {
            model: [1, 2, 3, 4, 5]
            Rectangle {
                required property var modelData
                readonly property bool focused: !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
                readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === modelData)
                width: focused ? 16 : 6
                height: 6
                antialiasing: true; radius: 3
                color: focused ? "white" : (occupied ? Settings.dim : "#3a3a3a")
                Behavior on width { NumberAnimation { duration: 150 } }
            }
        }
    }
    Text {
        anchors.centerIn: parent
        width: parent.width - 4
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        visible: s.kind !== "workspaces" && s.kind !== "none"
        color: "white"
        font.pixelSize: 11
        text: s.txt
    }
    Icon {
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        visible: s.kind === "weather" && !!Weather.cur
        name: Weather.cur ? Weather.icon(Weather.cur.weather_code) : ""
    }
    Icon {
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        visible: s.kind === "battery" && !!UPower.displayDevice && UPower.displayDevice.isPresent
        name: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging
              ? "battery-charging" : "battery"
    }
}
