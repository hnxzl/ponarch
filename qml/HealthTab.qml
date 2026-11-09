import QtQuick
import QtQuick.Layouts

RowLayout {
    id: ht
    spacing: 8

    Component.onCompleted: Health.norm()

    // rings
    Rectangle {
        Layout.preferredWidth: 150
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile

        Canvas {
            id: ring
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 14
            width: 110
            height: 110
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.lineWidth = 8
                ctx.lineCap = "round"
                const rings = [
                    { v: Health.move / Health.moveGoal, r: 48, c: "#43c5a0" },
                    { v: Health.water / Health.waterGoal, r: 36, c: "#4aa8ff" },
                    { v: Health.breath / Health.breathGoal, r: 24, c: "#a97bff" }
                ]
                for (let i = 0; i < rings.length; i++) {
                    ctx.strokeStyle = "#2a2a2e"
                    ctx.beginPath(); ctx.arc(55, 55, rings[i].r, 0, Math.PI * 2); ctx.stroke()
                    const v = Math.min(1, rings[i].v)
                    if (v > 0) {
                        ctx.strokeStyle = rings[i].c
                        ctx.beginPath(); ctx.arc(55, 55, rings[i].r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * v); ctx.stroke()
                    }
                }
            }
            Connections {
                target: Health
                function onWaterChanged() { ring.requestPaint() }
                function onMoveChanged() { ring.requestPaint() }
                function onBreathChanged() { ring.requestPaint() }
            }
            Component.onCompleted: requestPaint()
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            spacing: 2
            Text { color: "#43c5a0"; font.pixelSize: 11; text: Health.move + "/" + Health.moveGoal }
            Text { color: "#4aa8ff"; font.pixelSize: 11; text: Health.water + "/" + Health.waterGoal }
            Text { color: "#a97bff"; font.pixelSize: 11; text: Health.breath + "/" + Health.breathGoal }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
            antialiasing: true; radius: 12; color: Settings.tile
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 4
                Text { color: "white"; font.pixelSize: 12; font.bold: true; text: "Minum" }
                RowLayout {
                    spacing: 10
                    Text { color: "white"; font.pixelSize: 18; text: "−"
                           MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Health.addWater(-1) } }
                    Text { color: "white"; font.pixelSize: 18; font.bold: true; text: Health.water }
                    Text { color: "white"; font.pixelSize: 18; text: "+"
                           MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Health.addWater(1) } }
                }
                Item { Layout.fillHeight: true }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
            antialiasing: true; radius: 12; color: Settings.tile
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 4
                Text { color: "white"; font.pixelSize: 12; font.bold: true; text: "Gerak" }
                Item { Layout.fillHeight: true }
                Tile { Layout.fillWidth: true; implicitHeight: 22; label: "✓"; onClicked: Health.addMove() }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
            antialiasing: true; radius: 12; color: Settings.tile
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 4
                Text { color: "white"; font.pixelSize: 12; font.bold: true; text: "Napas" }
                Text { color: Settings.dim; font.pixelSize: 11; text: Health.breathing ? Health.phase : "" }
                Item { Layout.fillHeight: true }
                Tile {
                    Layout.fillWidth: true; implicitHeight: 22
                    label: Health.breathing ? "Berhenti" : "Mulai"
                    active: Health.breathing
                    onClicked: { if (Health.breathing) Health.stopBreath(); else Health.startBreath() }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 1
            antialiasing: true; radius: 12; color: Settings.tile
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 4
                Text { color: "white"; font.pixelSize: 12; font.bold: true; text: "Mata" }
                Item { Layout.fillHeight: true }
                Tile {
                    Layout.fillWidth: true; implicitHeight: 22
                    label: Settings.eyeBreak ? "Aktif" : "Nyalakan"
                    active: Settings.eyeBreak
                    onClicked: Settings.eyeBreak = !Settings.eyeBreak
                }
            }
        }
    }
}
