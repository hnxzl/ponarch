import QtQuick
import QtQuick.Layouts

RowLayout {
    id: wt
    spacing: 8

    Component.onCompleted: Weather.ensure()

    Rectangle {
        Layout.preferredWidth: 170
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 2

            Text { color: Settings.dim; font.pixelSize: 11; text: Loc.city }
            RowLayout {
                spacing: 8
                Icon { width: 38; height: 38; name: Weather.cur ? Weather.icon(Weather.cur.weather_code) : "weather-cloud" }
                Text {
                    color: "white"; font.pixelSize: 36; font.bold: true
                    text: Weather.cur ? Math.round(Weather.cur.temperature_2m) + "°" : "—"
                }
            }
            Text { color: "white"; font.pixelSize: 13; text: Weather.cur ? Weather.desc(Weather.cur.weather_code) : (Weather.loading ? "Memuat…" : "Tidak ada data") }
            Item { Layout.fillHeight: true }
            Text {
                color: Settings.dim; font.pixelSize: 11
                visible: !!Weather.cur
                text: Weather.cur ? "Terasa " + Math.round(Weather.cur.apparent_temperature) + "°  ·  " + Weather.cur.relative_humidity_2m + "%  ·  "
                                    + Math.round(Weather.cur.wind_speed_10m) + " km/j" : ""
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: Weather.days
                ColumnLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        color: index === 0 ? "white" : Settings.dim
                        font.pixelSize: 11
                        text: index === 0 ? "Hari ini" : Qt.formatDate(new Date(modelData.day), "ddd")
                    }
                    Icon { Layout.alignment: Qt.AlignHCenter; width: 22; height: 22; name: Weather.icon(modelData.code) }
                    Text { Layout.alignment: Qt.AlignHCenter; color: "white"; font.pixelSize: 12; text: modelData.max + "°" }
                    Text { Layout.alignment: Qt.AlignHCenter; color: Settings.dim; font.pixelSize: 11; text: modelData.min + "°" }
                    Item { Layout.fillHeight: true }
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            color: Settings.dim
            font.pixelSize: 11
            text: "Refresh"
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: Weather.refresh() }
        }
    }
}
