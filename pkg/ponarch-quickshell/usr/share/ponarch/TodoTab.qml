import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: tt
    spacing: 6

    Field {
        id: inp
        Layout.fillWidth: true
        placeholder: "Tugas"
        onAccepted: value => { Todo.add(value); inp.clear() }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: Todo.items

        delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width
            height: 28
            antialiasing: true; radius: 8
            color: Settings.tile

            Rectangle {
                id: box
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                antialiasing: true; radius: 7
                color: modelData.done ? Settings.accentColor : "transparent"
                border.width: 1
                border.color: modelData.done ? Settings.accentColor : Settings.faint
            }
            Text {
                anchors.left: box.right
                anchors.leftMargin: 8
                anchors.right: del.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                color: modelData.done ? Settings.faint : "white"
                font.pixelSize: 12
                font.strikeout: modelData.done
                text: modelData.text
            }
            MouseArea {
                anchors.left: parent.left
                anchors.right: del.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                cursorShape: Qt.PointingHandCursor
                onClicked: Todo.toggle(index)
            }
            Text {
                id: del
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: Settings.dim
                font.pixelSize: 12
                text: "✕"
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Todo.remove(index)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            color: Settings.faint
            font.pixelSize: 12
            text: ""
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            color: Settings.dim
            font.pixelSize: 11
            text: Todo.openCount + " aktif · " + (Todo.items.length - Todo.openCount) + " selesai"
        }
        Item { Layout.fillWidth: true }
        Text {
            color: Settings.dim
            font.pixelSize: 11
            text: "Clear"
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Todo.clearDone()
            }
        }
    }
}
