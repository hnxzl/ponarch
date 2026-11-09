import QtQuick

Rectangle {
    id: tile
    property string label: ""
    property bool active: false
    signal clicked()
    implicitHeight: 30
    antialiasing: true; radius: 10
    color: active ? Settings.accentSoft : Settings.tile

    Text {
        anchors.centerIn: parent
        width: parent.width - 8
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: tile.label
        color: "white"
        font.pixelSize: 11
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
