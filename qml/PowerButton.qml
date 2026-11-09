import QtQuick
import Quickshell

Rectangle {
    id: b
    property string label: ""
    property var cmd: []
    property bool confirm: true
    property bool armed: false
    implicitWidth: 70
    implicitHeight: 28
    antialiasing: true; radius: 10
    color: armed ? "#8c3b3b" : Settings.tile

    Text {
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 11
        text: b.armed ? "Sure?" : b.label
    }
    Timer { id: t; interval: 3000; onTriggered: b.armed = false }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!b.confirm || b.armed) { b.armed = false; Quickshell.execDetached(b.cmd) }
            else { b.armed = true; t.restart() }
        }
    }
}
