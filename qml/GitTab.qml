import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: gt
    spacing: 6

    Component.onCompleted: Gh.ensure()

    RowLayout {
        Layout.fillWidth: true
        Text { color: Settings.dim; font.pixelSize: 11; text: "Review" }
        Item { Layout.fillWidth: true }
        Tile { Layout.preferredWidth: 70; implicitHeight: 24; label: Gh.state === "loading" ? "…" : "Refresh"; onClicked: Gh.refresh() }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: Gh.prs
        delegate: Rectangle {
            required property var modelData
            width: list.width
            height: 40
            antialiasing: true; radius: 8
            color: Settings.tile
            Text {
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.top: parent.top; anchors.topMargin: 5
                color: Settings.dim; font.pixelSize: 10
                text: (modelData.repository ? modelData.repository.nameWithOwner : "") + " #" + modelData.number
            }
            Text {
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.bottom: parent.bottom; anchors.bottomMargin: 5
                elide: Text.ElideRight; color: "white"; font.pixelSize: 12
                text: modelData.title
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Sys.run("xdg-open '" + modelData.url + "'")
            }
        }
        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            horizontalAlignment: Text.AlignHCenter
            color: Settings.faint; font.pixelSize: 12
            text: Gh.state === "loading" ? "…" : Gh.state === "err" ? "gh belum login" : "Kosong"
        }
    }
}
