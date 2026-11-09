import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: sc
    spacing: 6

    property var rows: []
    property real total: 0

    function rebuild() {
        const keys = Object.keys(ScreenTime.apps)
        const set = {}
        keys.forEach(k => { set[k] = true })
        Object.keys(ScreenTime.pend).forEach(k => { set[k] = true })
        const arr = Object.keys(set).filter(k => k !== "").map(k => ({ name: k, secs: ScreenTime.seconds(k) }))
        arr.sort((a, b) => b.secs - a.secs)
        rows = arr.slice(0, 7)
        total = arr.reduce((s, x) => s + x.secs, 0)
    }
    function fmt(s) {
        const m = Math.round(s / 60)
        return m >= 60 ? Math.floor(m / 60) + "j " + (m % 60) + "m" : m + "m"
    }

    Component.onCompleted: { ScreenTime.persist(); rebuild() }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: { ScreenTime.accrue(); sc.rebuild() } }

    RowLayout {
        Layout.fillWidth: true
        Text { color: "white"; font.pixelSize: 22; font.bold: true; text: sc.fmt(sc.total) }
        Text { color: Settings.dim; font.pixelSize: 11; text: "" }
    }

    Repeater {
        model: sc.rows
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8
            Text { Layout.preferredWidth: 100; elide: Text.ElideRight; color: Settings.soft; font.pixelSize: 11; text: modelData.name }
            Rectangle {
                Layout.fillWidth: true; height: 6; antialiasing: true; radius: 3; color: "#333333"
                Rectangle { height: parent.height; antialiasing: true; radius: 3; color: Settings.accentColor
                            width: sc.total > 0 ? parent.width * modelData.secs / sc.total : 0 }
            }
            Text { Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight; color: "white"; font.pixelSize: 11; text: sc.fmt(modelData.secs) }
        }
    }
    Item { Layout.fillHeight: true }
    Text {
        visible: sc.rows.length === 0
        color: Settings.faint; font.pixelSize: 12
        text: "—"
    }
}
