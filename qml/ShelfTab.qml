import QtQuick
import QtQuick.Layouts

RowLayout {
    id: st
    spacing: 8

    // klik tile = jalankan aksi untuk semua isi Shelf; lepas file ke tile = aksi untuk file itu
    function act(name, paths) { Shelf.run(name, paths) }

    Rectangle {
        Layout.preferredWidth: 150
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            RowLayout {
                Text { color: Settings.dim; font.pixelSize: 11; text: Shelf.items.length }
                Item { Layout.fillWidth: true }
                Text {
                    color: Settings.dim; font.pixelSize: 11; text: "Clear"
                    MouseArea { anchors.fill: parent; anchors.margins: -3; cursorShape: Qt.PointingHandCursor; onClicked: Shelf.clear() }
                }
            }
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 3
                model: Shelf.items
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 24
                    antialiasing: true; radius: 6
                    color: "#26262a"
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.CopyAction
                    Drag.mimeData: ({ "text/uri-list": "file://" + modelData })
                    DragHandler {
                        target: null
                        onActiveChanged: row.Drag.active = active
                    }
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 6
                        anchors.right: rm.left; anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideMiddle; color: "white"; font.pixelSize: 11
                        text: Shelf.nameOf(row.modelData)
                    }
                    Text {
                        id: rm
                        anchors.right: parent.right; anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: Settings.dim; font.pixelSize: 11; text: "✕"
                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Shelf.remove(row.index) }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    color: Settings.faint; font.pixelSize: 11
                    text: "Drop"
                }
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 3
        columnSpacing: 6
        rowSpacing: 6

        DropTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
                   icon: "⇩"; label: "Shelf"; onDropped: p => st.act("shelf", p) }
        DropTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
                   icon: "⇪"; label: "Share"; onDropped: p => st.act("share", p); onClicked: st.act("share", Shelf.items) }
        DropTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
                   icon: "▣"; label: "Compress"; onDropped: p => st.act("zip", p); onClicked: st.act("zip", Shelf.items) }
        DropTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
                   icon: "▢"; label: "Extract"; onDropped: p => st.act("extract", p); onClicked: st.act("extract", Shelf.items) }
        DropTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
                   icon: "◩"; label: "→ PNG"; onDropped: p => st.act("convert", p); onClicked: st.act("convert", Shelf.items) }
        DropTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
                   icon: "⧉"; label: "Copy to…"; onDropped: p => st.act("copy", p); onClicked: st.act("copy", Shelf.items) }
        DropTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
                   icon: "➜"; label: "Move to…"; onDropped: p => st.act("move", p); onClicked: st.act("move", Shelf.items) }
        DropTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
                   icon: "↗"; label: "Open"; onDropped: p => st.act("open", p); onClicked: st.act("open", Shelf.items) }
        DropTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
                   icon: "✕"; label: "Trash"; onDropped: p => st.act("trash", p); onClicked: st.act("trash", Shelf.items) }
    }
}
