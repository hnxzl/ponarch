import QtQuick
import QtQuick.Layouts

Rectangle {
    id: t
    property string label: ""
    property string icon: ""
    signal dropped(var paths)
    signal clicked()
    antialiasing: true; radius: 10
    color: da.containsDrag ? Settings.accentSoft : Settings.tile

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0
        Text { Layout.alignment: Qt.AlignHCenter; color: "white"; font.pixelSize: 20; text: t.icon }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: t.clicked()
    }
    DropArea {
        id: da
        anchors.fill: parent
        onDropped: drop => {
            t.dropped(Shelf.pathsFrom(drop.urls))
            drop.accept()
        }
    }
}
