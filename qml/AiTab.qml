import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: at
    spacing: 6

    Connections {
        target: AI
        function onChatChanged() { Qt.callLater(() => list.positionViewAtEnd()) }
    }
    Component.onCompleted: Qt.callLater(() => list.positionViewAtEnd())

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Tile { Layout.preferredWidth: 80; implicitHeight: 24; label: Settings.aiProvider; onClicked: AI.cycleProvider() }
        Text { color: Settings.dim; font.pixelSize: 11; text: AI.model }
        Item { Layout.fillWidth: true }
        Text {
            color: AI.ready ? Settings.dim : "#e8688a"; font.pixelSize: 11
            text: AI.ready ? "Hapus chat" : "tanpa kunci"
            MouseArea { anchors.fill: parent; anchors.margins: -4; enabled: AI.ready; cursorShape: Qt.PointingHandCursor; onClicked: AI.clearChat() }
        }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 6
        model: AI.chat
        delegate: Item {
            required property var modelData
            readonly property real maxW: list.width * 0.86
            readonly property bool mine: modelData.role === "user"
            width: list.width
            height: bubble.height
            Rectangle {
                id: bubble
                anchors.right: parent.mine ? parent.right : undefined
                anchors.left: parent.mine ? undefined : parent.left
                width: parent.maxW
                height: txt.implicitHeight + 12
                antialiasing: true; radius: 10
                color: parent.modelData.err ? "#5a2a2a" : (parent.mine ? Settings.accentSoft : Settings.tile)
                Text {
                    id: txt
                    x: 8; y: 6
                    width: parent.width - 16
                    wrapMode: Text.Wrap
                    color: "white"
                    font.pixelSize: 12
                    text: parent.parent.modelData.content
                }
            }
        }
        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            color: Settings.faint; font.pixelSize: 12
            text: ""
        }
    }

    Field {
        id: inp
        Layout.fillWidth: true
        placeholder: AI.busy ? "Menunggu balasan…" : "Tulis pesan (Enter)"
        onAccepted: value => { AI.send(value); inp.clear() }
    }
}
