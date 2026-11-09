import QtQuick
import Quickshell.Io

Item {
    id: w
    property string label: ""
    property string exec: ""
    property int pollSeconds: 10
    property string out: "…"
    implicitHeight: 20

    Process {
        id: p
        command: ["sh", "-c", w.exec]
        stdout: StdioCollector { onStreamFinished: w.out = text.trim() }
    }
    Timer {
        running: w.exec !== ""
        repeat: true
        triggeredOnStart: true
        interval: Math.max(1, w.pollSeconds) * 1000
        onTriggered: { if (!p.running) p.running = true }
    }

    Text {
        id: lbl
        anchors.verticalCenter: parent.verticalCenter
        width: 70
        color: Settings.dim
        font.pixelSize: 11
        elide: Text.ElideRight
        text: w.label
    }
    Text {
        anchors.left: lbl.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: "white"
        font.pixelSize: 11
        elide: Text.ElideRight
        text: w.out
    }
}
