import QtQuick
import QtQuick.Layouts

RowLayout {
    spacing: 8

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: [{ id: "focus", n: "Focus" }, { id: "short", n: "Short" }, { id: "long", n: "Long" },
                            { id: "timer", n: "Timer" }, { id: "stopwatch", n: "Watch" }]
                    Tile {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 10
                        implicitHeight: 24
                        label: modelData.n
                        active: Pomo.mode === modelData.id
                        onClicked: Pomo.setMode(modelData.id)
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: "white"
                font.pixelSize: 36
                font.bold: true
                text: Pomo.label
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                Text {
                    visible: Pomo.mode === "timer"
                    color: Settings.dim; font.pixelSize: 16; text: "−5"
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Pomo.adjustTimer(-5) }
                }
                Text { color: Settings.dim; font.pixelSize: 11; text: Pomo.modeName }
                Text {
                    visible: Pomo.mode === "timer"
                    color: Settings.dim; font.pixelSize: 16; text: "+5"
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Pomo.adjustTimer(5) }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 4
                antialiasing: true; radius: 2
                color: "#333333"
                visible: Pomo.total > 0
                Rectangle {
                    height: parent.height
                    antialiasing: true; radius: 2
                    color: Settings.accentColor
                    width: Pomo.total > 0 ? parent.width * (1 - Pomo.remaining / Pomo.total) : 0
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 26
                Text {
                    color: "white"; font.pixelSize: 20; text: "↺"
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Pomo.reset() }
                }
                Text {
                    color: "white"; font.pixelSize: 24
                    text: Pomo.running ? "⏸" : "▶"
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Pomo.toggle() }
                }
                Text {
                    color: "white"; font.pixelSize: 20; text: "⏭"
                    opacity: Pomo.mode === "timer" || Pomo.mode === "stopwatch" ? 0.3 : 1
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Pomo.skip() }
                }
            }
        }
    }

    Rectangle {
        Layout.preferredWidth: 100
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text { Layout.alignment: Qt.AlignHCenter; color: "white"; font.pixelSize: 30; font.bold: true; text: Pomo.sessions }
        }
    }
}
