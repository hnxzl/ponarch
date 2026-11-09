import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: nt
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Item { Layout.fillWidth: true }
        Tile { Layout.preferredWidth: 34; implicitHeight: 24; label: "☾"; active: Dnd.on; onClicked: Dnd.toggle() }
        Tile { Layout.preferredWidth: 34; implicitHeight: 24; label: "✕"; onClicked: NotifLog.clear() }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: NotifLog.items
        delegate: Rectangle {
            required property var modelData
            width: list.width
            height: 54
            antialiasing: true; radius: 8
            color: Settings.tile
            Text {
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.top: parent.top; anchors.topMargin: 6
                color: Settings.faint; font.pixelSize: 10
                text: Qt.formatTime(new Date(modelData.t), "HH:mm")
            }
            NotifIcon {
                id: ico
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                app: modelData.app; icon: modelData.icon || ""; de: modelData.de || ""; img: modelData.img || ""
            }
            Column {
                anchors.left: ico.right; anchors.leftMargin: 10
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Text { width: parent.width - 40; elide: Text.ElideRight; color: Settings.dim; font.pixelSize: 10; text: modelData.app }
                Text { width: parent.width; elide: Text.ElideRight; color: "white"; font.pixelSize: 12; font.bold: true; text: modelData.summary }
                Text { width: parent.width; elide: Text.ElideRight; color: Settings.soft; font.pixelSize: 10; text: (modelData.body || "").replace(/\n/g, " ") }
            }
        }
        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            color: Settings.faint; font.pixelSize: 12
            text: Settings.notifLog ? "Kosong" : "Log mati"
        }
    }
}
