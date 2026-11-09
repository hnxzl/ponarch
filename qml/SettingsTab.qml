import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: st
    spacing: 8

    property string page: "look"

    readonly property var slotKinds: ["none", "workspaces", "battery", "date", "pomodoro", "prayer", "weather", "event"]
    readonly property var providers: ["claude", "gemini", "openai", "ollama"]
    function nextSlot(cur) { return slotKinds[(slotKinds.indexOf(cur) + 1) % slotKinds.length] }
    function nextIn(list, cur) { return list[(list.indexOf(cur) + 1) % list.length] }

    property bool dragging: false
    property int target: 0
    function enable(id) { if (!Settings.tabs.includes(id)) Settings.tabs = Settings.tabs.concat([id]) }
    function disable(id) { Settings.tabs = Settings.tabs.filter(k => k !== id) }
    function drop(from, to) {
        if (to < 0 || to === from) return
        const a = Settings.tabs.slice()
        const m = a.splice(from, 1)[0]
        a.splice(to, 0, m)
        Settings.tabs = a
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: [{ id: "look", n: "◐" }, { id: "tabs", n: "▦" }, { id: "more", n: "⋯" }]
            Tile {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 10
                implicitHeight: 26
                label: modelData.n
                active: st.page === modelData.id
                onClicked: st.page = modelData.id
            }
        }
    }

    // ---------------- Look ----------------
    ColumnLayout {
        visible: st.page === "look"
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Tile { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Black"; active: Settings.mode === "black"; onClicked: Settings.mode = "black" }
            Tile { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Glass"; active: Settings.mode === "glass"; onClicked: Settings.mode = "glass" }
            Tile { Layout.fillWidth: true; Layout.preferredWidth: 10; label: "Color"; active: Settings.mode === "color"; onClicked: Settings.mode = "color" }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: ["#5b7cff", "#e8688a", "#43c5a0", "#f0a54a", "#a97bff", "#ffffff"]
                Rectangle {
                    required property string modelData
                    width: 18; height: 18; antialiasing: true; radius: 9
                    color: modelData
                    border.width: Settings.accent === modelData ? 2 : 0
                    border.color: "white"
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.accent = parent.modelData }
                }
            }
            Item { Layout.fillWidth: true }
            Tile { Layout.preferredWidth: 84; implicitHeight: 24
                   label: Settings.accentFromWall ? "● wall" : "● manual"; active: Settings.accentFromWall
                   onClicked: Settings.accentFromWall = !Settings.accentFromWall }
            Tile { Layout.preferredWidth: 96; implicitHeight: 24
                   label: "◇ " + ({ normal: "normal", wallpaper: "wall", app: "app" })[Settings.glassTint]
                   active: Settings.glassTint !== "normal"
                   onClicked: Settings.glassTint = ({ normal: "wallpaper", wallpaper: "app", app: "normal" })[Settings.glassTint] ?? "normal" }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 14
            rowSpacing: 6
            Slider {
                Layout.fillWidth: true; Layout.preferredWidth: 10; labelWidth: 20
                label: "◑"
                value: (Settings.glassOpacity - 0.2) / 0.8
                valueText: Math.round(Settings.glassOpacity * 100) + "%"
                onMoved: v => Settings.glassOpacity = Math.round((0.2 + v * 0.8) * 100) / 100
            }
            Slider {
                Layout.fillWidth: true; Layout.preferredWidth: 10; labelWidth: 20
                label: "◠"
                value: (Settings.radius - 12) / 20
                valueText: Settings.radius + "px"
                onMoved: v => Settings.radius = Math.round(12 + v * 20)
            }
            Slider {
                Layout.fillWidth: true; Layout.preferredWidth: 10; labelWidth: 20
                label: "↕"
                value: Settings.gap / 40
                valueText: Settings.gap + "px"
                onMoved: v => Settings.gap = Math.round(v * 40)
            }
            Slider {
                Layout.fillWidth: true; Layout.preferredWidth: 10; labelWidth: 20
                label: "◷"
                value: Settings.hoverDelay / 800
                valueText: Settings.hoverDelay + "ms"
                onMoved: v => Settings.hoverDelay = Math.round(v * 800)
            }
            Slider {
                Layout.fillWidth: true; Layout.preferredWidth: 10; labelWidth: 20
                label: "N"
                value: (Settings.notchWidth - 200) / 160
                valueText: Settings.notchWidth + "px"
                onMoved: v => Settings.notchWidth = Math.round(200 + v * 160)
            }
            Slider {
                Layout.fillWidth: true; Layout.preferredWidth: 10; labelWidth: 20
                label: "P"
                value: (Settings.panelWidth - 480) / 240
                valueText: Settings.panelWidth + "px"
                onMoved: v => Settings.panelWidth = Math.round(480 + v * 240)
            }
            Slider {
                Layout.fillWidth: true; Layout.preferredWidth: 10; labelWidth: 20
                label: "H"
                value: (Settings.panelHeight - 320) / 220
                valueText: Settings.panelHeight + "px"
                onMoved: v => Settings.panelHeight = Math.round(320 + v * 220)
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Tile { Layout.fillWidth: true; Layout.preferredWidth: 10
                   label: "Hover"; active: Settings.hoverOpen
                   onClicked: Settings.hoverOpen = !Settings.hoverOpen }
            Tile { Layout.fillWidth: true; Layout.preferredWidth: 10
                   label: "◀ " + Settings.leftSlot; onClicked: Settings.leftSlot = st.nextSlot(Settings.leftSlot) }
            Tile { Layout.fillWidth: true; Layout.preferredWidth: 10
                   label: Settings.rightSlot + " ▶"; onClicked: Settings.rightSlot = st.nextSlot(Settings.rightSlot) }
        }
    }

    // ---------------- Tabs ----------------
    Flickable {
        id: tf
        visible: st.page === "tabs"
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: tcol.implicitHeight
        interactive: !st.dragging && contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: tcol
            width: tf.width
            spacing: 6

            Text { color: Settings.dim; font.pixelSize: 10; text: "" }

            Item {
                id: grid
                Layout.fillWidth: true
                readonly property int cols: 5
                readonly property real cw: width / cols
                readonly property real chh: 30
                Layout.preferredHeight: Math.max(1, Math.ceil(Settings.tabs.length / cols)) * chh

                Rectangle {
                    visible: st.dragging
                    x: (st.target % grid.cols) * grid.cw + 2
                    y: Math.floor(st.target / grid.cols) * grid.chh + 2
                    width: grid.cw - 4; height: grid.chh - 4
                    antialiasing: true; radius: 9; color: "transparent"
                    border.width: 1; border.color: Settings.accentColor
                }

                Repeater {
                    model: Settings.tabs
                    delegate: Rectangle {
                        id: cell
                        required property string modelData
                        required property int index
                        readonly property var mod: Mods.all.find(m => m.id === modelData)
                        readonly property bool dragged: dh.active
                        readonly property real bx: index % grid.cols * grid.cw + 2
                        readonly property real by: Math.floor(index / grid.cols) * grid.chh + 2
                        readonly property int tgt: Math.max(0, Math.min(Settings.tabs.length - 1,
                            Math.floor((by + height / 2 + dh.translation.y) / grid.chh) * grid.cols
                            + Math.floor((bx + width / 2 + dh.translation.x) / grid.cw)))
                        x: bx + (dragged ? dh.translation.x : 0)
                        y: by + (dragged ? dh.translation.y : 0)
                        width: grid.cw - 4
                        height: grid.chh - 4
                        z: dragged ? 10 : 1
                        antialiasing: true; radius: 9
                        color: dragged ? Settings.accentSoft : Settings.tile
                        opacity: dragged ? 0.9 : 1
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 6
                            anchors.right: rm.left; anchors.rightMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight; color: "white"; font.pixelSize: 10
                            text: cell.mod ? cell.mod.icon + " " + cell.mod.name : cell.modelData
                        }
                        Text {
                            id: rm
                            anchors.right: parent.right; anchors.rightMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            color: Settings.dim; font.pixelSize: 10; text: "✕"
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: st.disable(cell.modelData)
                            }
                        }
                        DragHandler {
                            id: dh
                            target: null
                            onActiveChanged: {
                                st.dragging = active
                                if (active) st.target = cell.index
                                else st.drop(cell.index, st.target)
                            }
                            onTranslationChanged: { if (active) st.target = cell.tgt }
                        }
                    }
                }
            }

            Text {
                visible: Mods.all.some(m => !Settings.tabs.includes(m.id))
                color: Settings.dim; font.pixelSize: 10; text: ""
            }
            Flow {
                id: disabledRow
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Mods.all.filter(m => !Settings.tabs.includes(m.id))
                    Tile {
                        required property var modelData
                        width: 92; implicitHeight: 24
                        label: "+ " + modelData.icon + " " + modelData.name
                        onClicked: st.enable(modelData.id)
                    }
                }
            }
        }
    }

    // ---------------- More ----------------
    GridLayout {
        visible: st.page === "more"
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 3
        columnSpacing: 6
        rowSpacing: 6

        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "HUD"; active: Settings.hud; onClicked: Settings.hud = !Settings.hud }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Cava"; active: Settings.cava; onClicked: Settings.cava = !Settings.cava }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Cuaca dashboard"; active: Settings.weatherDashboard
               onClicked: Settings.weatherDashboard = !Settings.weatherDashboard }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Lirik"; active: Settings.lyrics; onClicked: Settings.lyrics = !Settings.lyrics }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Lirik·notch"; active: Settings.lyricsClosed; onClicked: Settings.lyricsClosed = !Settings.lyricsClosed }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Mata"; active: Settings.eyeBreak; onClicked: Settings.eyeBreak = !Settings.eyeBreak }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: Settings.waterEvery > 0 ? "Air " + Settings.waterEvery + "m" : "Air"
               active: Settings.waterEvery > 0
               onClicked: Settings.waterEvery = ({ 0: 30, 30: 60, 60: 90, 90: 0 })[Settings.waterEvery] ?? 0 }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Hover ♪"; active: Settings.musicHover; onClicked: Settings.musicHover = !Settings.musicHover }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Pomo " + Settings.pomoStyle; active: Settings.pomoStyle !== "off"
               onClicked: Settings.pomoStyle = ({ strip: "ring", ring: "off", off: "strip" })[Settings.pomoStyle] ?? "strip" }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Popup"; active: Settings.notifToast; onClicked: Settings.notifToast = !Settings.notifToast }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Suara notif"; active: Settings.notifSound; onClicked: Settings.notifSound = !Settings.notifSound }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Popup screenshot"; active: Settings.notifScreenshotToast
               onClicked: Settings.notifScreenshotToast = !Settings.notifScreenshotToast }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Log"; active: Settings.notifLog; onClicked: Settings.notifLog = !Settings.notifLog }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "AI " + Settings.aiProvider; onClicked: Settings.aiProvider = st.nextIn(st.providers, Settings.aiProvider) }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: Settings.autoLocation ? "Lokasi auto" : "Lokasi manual"; active: Settings.autoLocation
               onClicked: Settings.autoLocation = !Settings.autoLocation }
        Tile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10; Layout.preferredHeight: 10
               label: "Acara " + Settings.calRemind + "m"
               onClicked: Settings.calRemind = ({ 5: 10, 10: 15, 15: 5 })[Settings.calRemind] ?? 10 }
    }
}
