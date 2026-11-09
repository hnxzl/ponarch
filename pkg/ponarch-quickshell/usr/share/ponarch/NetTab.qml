import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

ColumnLayout {
    id: nt
    spacing: 6

    property string page: "wifi"          // wifi | bt
    property string askFor: ""

    readonly property bool btOn: !!Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
    readonly property bool scanning: !!Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering

    Component.onCompleted: Net.ensure()

    function connectTo(n) {
        if (n.active) { Net.disconnect(n.ssid); return }
        if (n.secure && !n.saved) {
            askFor = n.ssid
            Qt.callLater(() => pw.focusIn())
            return
        }
        Net.connect(n.ssid, "")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Tile { Layout.preferredWidth: 80; label: "Wi-Fi"; active: Sys.wifiOn; onClicked: Sys.toggleWifi() }
        Tile { Layout.preferredWidth: 80; label: "BT"; active: nt.btOn
               onClicked: { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled } }
        Item { Layout.fillWidth: true }
        Tile { Layout.preferredWidth: 70; label: "Net"; active: nt.page === "wifi"; onClicked: nt.page = "wifi" }
        Tile { Layout.preferredWidth: 70; label: "BT"; active: nt.page === "bt"; onClicked: nt.page = "bt" }
    }

    // password prompt untuk jaringan baru
    RowLayout {
        Layout.fillWidth: true
        visible: nt.askFor !== "" && nt.page === "wifi"
        spacing: 6
        Text { color: Settings.soft; font.pixelSize: 11; text: nt.askFor }
        Field {
            id: pw
            Layout.fillWidth: true
            password: true
            placeholder: "Password (Enter)"
            onAccepted: value => { Net.connect(nt.askFor, value); nt.askFor = ""; pw.clear() }
        }
        Text {
            color: Settings.dim; font.pixelSize: 12; text: "✕"
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: nt.askFor = "" }
        }
    }

    // Wi-Fi list
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: nt.page === "wifi"
        clip: true
        spacing: 4
        model: Net.nets
        id: wl
        delegate: Rectangle {
            required property var modelData
            width: wl.width
            height: 30
            antialiasing: true; radius: 8
            color: modelData.active ? Settings.accentSoft : Settings.tile
            Text {
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.right: sig.left; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight; color: "white"; font.pixelSize: 12
                text: modelData.ssid + (modelData.secure ? "  ⚿" : "")
            }
            Text {
                id: sig
                anchors.right: act.left; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: Settings.dim; font.pixelSize: 11
                text: modelData.signal + "%"
            }
            Tile {
                id: act
                anchors.right: parent.right; anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 76; implicitHeight: 22
                label: modelData.active ? "Putuskan" : (modelData.saved ? "Sambung" : "Sambung")
                active: modelData.active
                onClicked: nt.connectTo(modelData)
            }
        }
        Text {
            anchors.centerIn: parent
            visible: wl.count === 0
            color: Settings.faint; font.pixelSize: 12
            text: Net.loading ? "…" : "Kosong"
        }
    }

    // Bluetooth devices
    ListView {
        id: bl
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: nt.page === "bt"
        clip: true
        spacing: 4
        model: Bluetooth.devices.values.filter(d => d.paired || d.connected || nt.scanning)
        delegate: Rectangle {
            required property var modelData
            width: bl.width
            height: 30
            antialiasing: true; radius: 8
            color: modelData.connected ? Settings.accentSoft : Settings.tile
            Text {
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.right: bat.left; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight; color: "white"; font.pixelSize: 12
                text: modelData.name || modelData.address
            }
            Text {
                id: bat
                anchors.right: bact.left; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: Settings.dim; font.pixelSize: 11
                text: modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : ""
            }
            Tile {
                id: bact
                anchors.right: parent.right; anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 76; implicitHeight: 22
                label: modelData.connected ? "Putuskan" : "Sambung"
                active: modelData.connected
                onClicked: { if (modelData.connected) modelData.disconnect(); else modelData.connect() }
            }
        }
        Text {
            anchors.centerIn: parent
            visible: bl.count === 0
            color: Settings.faint; font.pixelSize: 12
            text: nt.btOn ? "Kosong" : "Bluetooth mati"
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
            color: Settings.dim; font.pixelSize: 11
            text: nt.page === "wifi" ? "" : (nt.scanning ? "Memindai perangkat…" : "")
        }
        Item { Layout.fillWidth: true }
        Tile {
            Layout.preferredWidth: 70; implicitHeight: 24
            label: nt.page === "wifi" ? "Refresh" : (nt.scanning ? "Stop" : "Scan")
            onClicked: {
                if (nt.page === "wifi") Net.rescan()
                else if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
            }
        }
    }
}
