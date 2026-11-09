import QtQuick
import QtQuick.Layouts

// Teman kecil: kucing 2D yang matanya mengikuti kursor. Klik untuk mengobrol.
Item {
    id: bd
    property real mx: width / 2
    property real my: height / 2
    property string say: "Meow~"
    readonly property var lines: ["Meow!", "Sudah minum belum?", "Fokus dulu, ya.", "Waktunya istirahat sebentar?",
                                  "Ada " + Todo.openCount + " tugas lagi.", "Purr…", "Jangan lupa regangkan badan."]

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: mouse => { bd.mx = mouse.x; bd.my = mouse.y }
        onClicked: bd.say = bd.lines[Math.floor(Math.random() * bd.lines.length)]
    }

    Rectangle {
        id: cat
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 10
        width: 130; height: 96
        antialiasing: true; radius: 44
        color: "#e8a85a"

        Rectangle { x: 8;  y: -14; width: 34; height: 34; antialiasing: true; radius: 6; rotation: 45; color: "#e8a85a"; z: -1 }
        Rectangle { x: 88; y: -14; width: 34; height: 34; antialiasing: true; radius: 6; rotation: 45; color: "#e8a85a"; z: -1 }

        Repeater {
            model: [34, 96]
            Rectangle {
                required property int modelData
                x: modelData - 15; y: 28
                width: 30; height: 30; antialiasing: true; radius: 15
                color: "white"
                Rectangle {
                    readonly property real cx: parent.x + 15 + cat.x
                    readonly property real cy: parent.y + 15 + cat.y
                    readonly property real dx: bd.mx - cx
                    readonly property real dy: bd.my - cy
                    readonly property real d: Math.max(1, Math.sqrt(dx * dx + dy * dy))
                    width: 14; height: 14; antialiasing: true; radius: 7
                    color: "#222222"
                    x: 8 + Math.min(1, 40 / d) * dx / Math.max(1, d) * 5
                    y: 8 + Math.min(1, 40 / d) * dy / Math.max(1, d) * 5
                }
            }
        }
        Rectangle { x: 59; y: 58; width: 12; height: 8; antialiasing: true; radius: 4; color: "#e8688a" }
        Text { x: 56; y: 62; color: "#442200"; font.pixelSize: 14; text: "ω" }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 2
        width: sayText.implicitWidth + 20
        height: 24
        antialiasing: true; radius: 12
        color: Settings.tile
        Text { id: sayText; anchors.centerIn: parent; color: "white"; font.pixelSize: 11; text: bd.say }
    }
}
