import QtQuick

Item {
    id: s
    property real value: 0
    property string label: ""
    property int labelWidth: 30
    property string valueText: Math.round(value * 100) + "%"
    signal moved(real v)
    implicitHeight: 22

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => s.moved(Math.max(0, Math.min(1, s.value + e.angleDelta.y / 120 * 0.05)))
    }
    Text {
        id: lbl
        text: s.label
        color: Settings.dim
        font.pixelSize: 11
        width: s.labelWidth
        anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
        id: track
        anchors.left: lbl.right
        anchors.right: pct.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        antialiasing: true; radius: 3
        color: "#333333"
        Rectangle {
            height: parent.height
            antialiasing: true; radius: 3
            color: Settings.accentColor
            width: parent.width * Math.max(0, Math.min(1, s.value))
        }
        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -8
            anchors.bottomMargin: -8
            function setFrom(x) { s.moved(Math.max(0, Math.min(1, x / track.width))) }
            onPressed: mouse => setFrom(mouse.x)
            onPositionChanged: mouse => { if (pressed) setFrom(mouse.x) }
        }
    }
    Text {
        id: pct
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight
        color: "white"
        font.pixelSize: 11
        text: s.valueText
    }
}
