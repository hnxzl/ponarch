import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

// Tray: klik kiri = buka/aktifkan aplikasi, klik kanan = menu, klik tengah = aksi kedua.
RowLayout {
    id: tt
    spacing: 8

    property var sel: null            // item tray yang menunya sedang dibuka
    property var stack: []            // jalur submenu (QsMenuEntry), kosong = menu utama
    readonly property bool selAlive: !!sel && SystemTray.items.values.includes(sel)
    readonly property var cur: !selAlive ? null : (stack.length > 0 ? stack[stack.length - 1] : sel.menu)

    // "_" di label dbusmenu = mnemonic; "__" = garis bawah asli
    function clean(s) { return (s || "").replace(/__/g, "\u0001").replace(/_/g, "").replace(/\u0001/g, "_") }
    function close() { sel = null; stack = [] }
    function openMenu(it) { sel = it; stack = [] }

    QsMenuOpener { id: opener; menu: tt.cur }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile
        clip: true

        // daftar aplikasi tray
        Flow {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            visible: !tt.selAlive
            Repeater {
                model: SystemTray.items
                Rectangle {
                    id: cell
                    required property var modelData
                    visible: modelData.status > 0           // 0 = Passive (disembunyikan)
                    width: 38; height: 38
                    antialiasing: true; radius: 10
                    color: ma.containsMouse ? "#22ffffff" : "transparent"
                    Image {
                        id: img
                        anchors.centerIn: parent
                        width: 24; height: 24
                        sourceSize: Qt.size(48, 48)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: cell.modelData.icon
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: img.status !== Image.Ready
                        color: "white"; font.pixelSize: 14; font.bold: true
                        text: (cell.modelData.title || cell.modelData.id || "?").charAt(0).toUpperCase()
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: m => {
                            const it = cell.modelData
                            if (m.button === Qt.RightButton) { if (it.hasMenu) tt.openMenu(it) }
                            else if (m.button === Qt.MiddleButton) it.secondaryActivate()
                            else if (it.onlyMenu) tt.openMenu(it)
                            else it.activate()
                        }
                    }
                }
            }
        }

        // menu klik kanan (menggantikan daftar, tombol ‹ / ✕ untuk kembali)
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4
            visible: tt.selAlive

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    color: Settings.accentColor; font.pixelSize: 14
                    text: tt.stack.length > 0 ? "‹" : "✕"
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (tt.stack.length > 0) tt.stack = tt.stack.slice(0, -1); else tt.close() }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: "white"; font.pixelSize: 12; font.bold: true
                    text: tt.stack.length > 0 ? tt.clean(tt.stack[tt.stack.length - 1].text)
                          : (tt.selAlive ? (tt.sel.title || tt.sel.id) : "")
                }
            }

            ListView {
                id: lv
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 1
                boundsBehavior: Flickable.StopAtBounds
                model: opener.children
                delegate: Item {
                    id: row
                    required property var modelData
                    width: lv.width
                    height: modelData.isSeparator ? 7 : 24

                    Rectangle {
                        visible: row.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        x: 6; width: parent.width - 12; height: 1
                        color: "#33ffffff"
                    }
                    Rectangle {
                        visible: !row.modelData.isSeparator
                        anchors.fill: parent
                        antialiasing: true; radius: 8
                        color: rma.containsMouse && row.modelData.enabled ? Settings.accentSoft : "transparent"
                        Text {
                            id: mark
                            x: 6; width: 12
                            anchors.verticalCenter: parent.verticalCenter
                            color: "white"; font.pixelSize: 11
                            text: row.modelData.buttonType === 0 ? ""
                                  : (row.modelData.checkState === Qt.Checked ? (row.modelData.buttonType === 2 ? "●" : "✓") : "")
                        }
                        Image {
                            id: eico
                            anchors.left: mark.right; anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: visible ? 14 : 0; height: 14
                            visible: row.modelData.icon !== "" && status === Image.Ready
                            sourceSize: Qt.size(28, 28)
                            source: row.modelData.icon
                        }
                        Text {
                            anchors.left: eico.right; anchors.leftMargin: 4
                            anchors.right: sub.left; anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            color: row.modelData.enabled ? "white" : Settings.faint
                            font.pixelSize: 11
                            text: tt.clean(row.modelData.text)
                        }
                        Text {
                            id: sub
                            anchors.right: parent.right; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.modelData.hasChildren
                            color: Settings.dim; font.pixelSize: 12; text: "›"
                        }
                        MouseArea {
                            id: rma
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: row.modelData.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (row.modelData.hasChildren) tt.stack = tt.stack.concat([row.modelData])
                                else { row.modelData.triggered(); tt.close() }
                            }
                        }
                    }
                }
            }
        }
    }
}
