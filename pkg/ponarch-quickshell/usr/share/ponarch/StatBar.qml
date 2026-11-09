import QtQuick

Item {
    id: b
    property string label: ""
    property real value: 0
    property string valueText: ""
    implicitHeight: 22

    Text {
        id: lbl
        text: b.label
        color: Settings.dim
        font.pixelSize: 11
        width: 48
        anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
        anchors.left: lbl.right
        anchors.right: val.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        antialiasing: true; radius: 3
        color: "#333333"
        Rectangle {
            height: parent.height
            antialiasing: true; radius: 3
            color: Settings.accentColor
            width: parent.width * Math.max(0, Math.min(1, b.value))
            Behavior on width { NumberAnimation { duration: 300 } }
        }
    }
    Text {
        id: val
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        horizontalAlignment: Text.AlignRight
        color: "white"
        font.pixelSize: 11
        text: b.valueText
    }
}
