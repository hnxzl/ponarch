import QtQuick

Row {
    id: v
    property bool running: false
    spacing: 2
    width: 23
    height: 18
    property var fake: [4, 8, 12, 8, 4]

    Timer {
        interval: 420
        repeat: true
        running: v.running && !Cava.ok
        onTriggered: v.fake = [0, 1, 2, 3, 4].map(() => 4 + Math.random() * 12)
    }

    Repeater {
        model: 5
        Item {
            id: cell
            required property int index
            width: 3
            height: v.height
            Rectangle {
                width: 3
                antialiasing: true
                radius: 1.5
                color: "white"
                height: Cava.ok ? 3 + Cava.levels[cell.index] * 15 : v.fake[cell.index]
                anchors.verticalCenter: parent.verticalCenter
                Behavior on height {
                    enabled: !Cava.ok
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }
}
