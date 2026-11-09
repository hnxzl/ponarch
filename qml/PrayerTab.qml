import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: pt
    spacing: 8

    property date now: new Date()
    readonly property var nxt: Prayer.nextInfo(now)

    Component.onCompleted: Prayer.ensure()
    Timer { interval: 30000; repeat: true; running: true; onTriggered: pt.now = new Date() }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Settings.accentColor
                font.pixelSize: 14
                font.bold: true
                text: pt.nxt ? pt.nxt.label : (Prayer.loading ? "Memuat…" : "Tidak ada data")
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: "white"
                font.pixelSize: 34
                font.bold: true
                text: pt.nxt ? Prayer.fmtLeft(pt.nxt.left) : "—"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Settings.dim
                font.pixelSize: 11
                text: pt.nxt ? "pukul " + pt.nxt.time + "  ·  " + Loc.city : Loc.city
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Prayer.names
            Rectangle {
                required property var modelData
                readonly property bool isNext: !!pt.nxt && pt.nxt.key === modelData[0]
                Layout.fillWidth: true
                Layout.preferredWidth: 10
                Layout.preferredHeight: 44
                antialiasing: true; radius: 10
                color: isNext ? Settings.accentSoft : Settings.tile
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Text { Layout.alignment: Qt.AlignHCenter; color: Settings.soft; font.pixelSize: 11; text: modelData[1] }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                        text: Prayer.times[modelData[0]] ?? "--:--"
                    }
                }
            }
        }
    }
}
