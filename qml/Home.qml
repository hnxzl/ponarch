import QtQuick
import QtQuick.Layouts
import Quickshell

RowLayout {
    id: home
    readonly property var player: Media.player
    property date now: new Date()
    spacing: 8
    property bool showLyrics: false
    readonly property bool hasTrack: !!player && player.trackTitle !== ""
    readonly property bool month: Settings.homeCal === "month"
    property int mOff: 0                       // geser bulan (mode month)
    readonly property date shown: new Date(now.getFullYear(), now.getMonth() + mOff, 1)
    readonly property int lead: (shown.getDay() + 6) % 7                       // Senin = kolom pertama
    readonly property int dim: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
    readonly property int cells: Math.ceil((lead + dim) / 7) * 7

    Timer {
        running: Media.playing
        interval: 1000
        repeat: true
        onTriggered: home.player.positionChanged()
    }

    // player card
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
                spacing: 10
                Rectangle {
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 58
                    antialiasing: true; radius: 10
                    color: "#2a2a2e"
                    clip: true
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(128, 128); asynchronous: true
                        source: home.player ? home.player.trackArtUrl : ""
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                        text: home.hasTrack ? home.player.trackTitle : Qt.formatDate(home.now, "dddd")
                    }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: Settings.dim
                        font.pixelSize: 11
                        text: home.hasTrack ? home.player.trackArtist : Qt.formatDate(home.now, "d MMMM yyyy")
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                height: 4
                antialiasing: true; radius: 2
                color: "#333333"
                visible: !!home.player && home.player.lengthSupported
                Rectangle {
                    height: parent.height
                    antialiasing: true; radius: 2
                    color: Settings.accentColor
                    width: home.player && home.player.length > 0
                           ? parent.width * Math.min(1, home.player.position / home.player.length) : 0
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24
                visible: !!home.player
                Repeater {
                    model: [{ g: "⏮", a: "prev" }, { g: "t", a: "toggle" }, { g: "⏭", a: "next" }]
                    Text {
                        required property var modelData
                        color: "white"
                        font.pixelSize: 20
                        text: modelData.g === "t" ? (home.player && home.player.isPlaying ? "⏸" : "▶") : modelData.g
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!home.player) return
                                if (modelData.a === "prev") home.player.previous()
                                else if (modelData.a === "next") home.player.next()
                                else home.player.togglePlaying()
                            }
                        }
                    }
                }
                Text {
                    color: home.showLyrics ? Settings.accentColor : Settings.dim
                    font.pixelSize: 18
                    text: "❝"
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            home.showLyrics = !home.showLyrics
                            if (home.showLyrics) Settings.lyrics = true
                        }
                    }
                }
            }
        }
    }

    // lyrics card
    Rectangle {
        visible: home.showLyrics
        Layout.preferredWidth: 190
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile
        clip: true
        Text {
            anchors.centerIn: parent
            visible: Lyrics.lines.length === 0
            color: Settings.faint; font.pixelSize: 12
            text: Lyrics.state === "loading" ? "Mencari lirik…" : "Lirik tidak ada"
        }
        ListView {
            id: ly
            anchors.fill: parent
            anchors.margins: 8
            visible: Lyrics.lines.length > 0
            model: Lyrics.lines
            interactive: false
            currentIndex: Lyrics.index
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: height / 2 - 12
            preferredHighlightEnd: height / 2 + 12
            highlightMoveDuration: 250
            delegate: Text {
                required property var modelData
                required property int index
                width: ly.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: index === Lyrics.index ? "white" : Settings.faint
                font.pixelSize: index === Lyrics.index ? 13 : 11
                font.bold: index === Lyrics.index
                text: modelData.text
            }
        }
    }

    // kalender: 7 hari ke depan, atau kotak sebulan
    Rectangle {
        visible: !home.showLyrics
        Layout.preferredWidth: home.month ? 176 : 120
        Layout.fillHeight: true
        antialiasing: true; radius: 14
        color: Settings.tile
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Settings.dim
                    font.pixelSize: 11
                    text: Qt.formatDate(home.month ? home.shown : home.now, "MMMM yyyy")
                }
                Text {
                    visible: home.month
                    color: Settings.dim; font.pixelSize: 13; text: "‹"
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: home.mOff-- }
                }
                Text {
                    visible: home.month
                    color: Settings.dim; font.pixelSize: 13; text: "›"
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: home.mOff++ }
                }
                Text {
                    color: Settings.accentColor; font.pixelSize: 12
                    text: home.month ? "☰" : "▦"
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { home.mOff = 0; Settings.homeCal = home.month ? "week" : "month" }
                    }
                }
            }

            // mode week
            Repeater {
                model: home.month ? 0 : 7
                Rectangle {
                    required property int index
                    readonly property date d: new Date(home.now.getFullYear(), home.now.getMonth(), home.now.getDate() + index)
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    antialiasing: true; radius: 6
                    color: index === 0 ? Settings.accentSoft : "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        color: "white"
                        font.pixelSize: 11
                        text: Qt.formatDate(parent.d, "ddd  d")
                    }
                }
            }

            // mode month
            Grid {
                visible: home.month
                Layout.fillWidth: true
                columns: 7
                readonly property real cw: width / 7
                Repeater {
                    model: home.month ? ["M", "T", "W", "T", "F", "S", "S"] : []
                    Text {
                        required property string modelData
                        width: parent.cw; height: 14
                        horizontalAlignment: Text.AlignHCenter
                        color: Settings.faint; font.pixelSize: 9
                        text: modelData
                    }
                }
                Repeater {
                    model: home.month ? home.cells : 0
                    Item {
                        required property int index
                        readonly property int day: index - home.lead + 1
                        readonly property bool ok: day >= 1 && day <= home.dim
                        readonly property bool today: ok && home.mOff === 0 && day === home.now.getDate()
                        width: parent.cw; height: 21
                        Rectangle {
                            anchors.centerIn: parent
                            width: 20; height: 19
                            antialiasing: true; radius: 6
                            visible: parent.today
                            color: Settings.accentSoft
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: parent.ok
                            color: parent.today ? "white" : Settings.soft
                            font.pixelSize: 10
                            font.bold: parent.today
                            text: parent.day
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
