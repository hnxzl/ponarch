import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: dt
    spacing: 8
    property date now: new Date()

    Timer { interval: 30000; repeat: true; running: true; onTriggered: dt.now = new Date() }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6
            RowLayout {
                Text { color: "white"; font.pixelSize: 30; font.bold: true; text: Math.round(Day.dayFrac(dt.now) * 100) + "%" }
                Text { color: Settings.dim; font.pixelSize: 12; text: Day.untilBed(dt.now) + " lagi tidur" }
            }
            Rectangle {
                Layout.fillWidth: true; height: 8; antialiasing: true; radius: 4; color: "#333333"
                Rectangle { height: parent.height; antialiasing: true; radius: 4; color: Settings.accentColor; width: parent.width * Day.dayFrac(dt.now) }
            }
            Item { Layout.fillHeight: true }
            Text {
                color: Settings.dim; font.pixelSize: 11
                text: Todo.openCount + " tugas"
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: [{ n: "MINGGU", f: "week" }, { n: "BULAN", f: "month" }, { n: "TAHUN", f: "year" }]
            Rectangle {
                required property var modelData
                readonly property real frac: modelData.f === "week" ? Day.weekFrac(dt.now)
                                           : modelData.f === "month" ? Day.monthFrac(dt.now) : Day.yearFrac(dt.now)
                Layout.fillWidth: true
                Layout.preferredWidth: 10
                Layout.preferredHeight: 62
                antialiasing: true; radius: 12
                color: Settings.tile
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 3
                    Text { color: Settings.dim; font.pixelSize: 10; text: modelData.n }
                    Text { color: "white"; font.pixelSize: 18; font.bold: true; text: Math.round(frac * 100) + "%" }
                    Rectangle {
                        Layout.fillWidth: true; height: 4; antialiasing: true; radius: 2; color: "#333333"
                        Rectangle { height: parent.height; antialiasing: true; radius: 2; color: Settings.accentColor; width: parent.width * frac }
                    }
                }
            }
        }
    }
}
