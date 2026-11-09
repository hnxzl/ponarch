import QtQuick
import QtQuick.Layouts

RowLayout {
    id: nt
    spacing: 8
    property int sel: 0

    function load() {
        area.text = Notes.items.length > 0 && sel < Notes.items.length ? Notes.items[sel].text : ""
    }
    Component.onCompleted: { if (sel >= Notes.items.length) sel = Math.max(0, Notes.items.length - 1); load() }
    onSelChanged: load()

    Timer {
        id: save
        interval: 600
        onTriggered: Notes.update(nt.sel, area.text)
    }

    ColumnLayout {
        Layout.preferredWidth: 130
        Layout.fillHeight: true
        spacing: 6

        Tile {
            Layout.fillWidth: true
            implicitHeight: 26
            label: "+ Baru"
            onClicked: { Notes.add(); nt.sel = 0; nt.load(); area.focusIn() }
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: Notes.items
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: list.width
                height: 28
                antialiasing: true; radius: 8
                color: index === nt.sel ? Settings.accentSoft : Settings.tile
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: "white"
                    font.pixelSize: 11
                    text: Notes.title(modelData.text)
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { save.stop(); nt.sel = index }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 6

        Area {
            id: area
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholder: ""
            readOnly: Notes.items.length === 0
            onEdited: save.restart()
        }
        RowLayout {
            Layout.fillWidth: true
            Text { color: Settings.dim; font.pixelSize: 11; text: Notes.items.length }
            Item { Layout.fillWidth: true }
            Text {
                color: Settings.dim; font.pixelSize: 11; text: "Hapus"
                visible: Notes.items.length > 0
                MouseArea {
                    anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        save.stop()
                        Notes.remove(nt.sel)
                        nt.sel = Math.max(0, Math.min(nt.sel, Notes.items.length - 1))
                        nt.load()
                    }
                }
            }
        }
    }

    Component.onDestruction: { if (save.running) { save.stop(); Notes.update(nt.sel, area.text) } }
}
