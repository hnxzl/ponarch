//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray

ShellRoot {
    id: root

    property bool pinned: false
    property bool open: false
    property string tab: "home"
    property bool toastOn: false
    property bool hidden: false
    property string tApp: ""
    property string tSum: ""
    property string tBody: ""
    property string tIcon: ""
    property string tDe: ""
    property string tImg: ""
    property var tn: null              // objek Notification (mode daemon); null di mode mendengarkan
    property int tActs: 0
    readonly property bool toasting: toastOn && !expanded
    // ukuran tujuan notch (tanpa animasi): dipakai pill dan mask input
    readonly property real tw: expanded ? Settings.panelWidth : (toasting ? 380 : (Hud.shown ? 260 : (pill.peek ? 320 : (pill.lyricMode ? 340 : Settings.notchWidth))))
    readonly property real th: expanded ? Settings.panelHeight : (toasting ? (tActs > 0 ? 88 : 56) : (strip.show ? 54 : 28))
    readonly property bool expanded: pinned || open

    // tab yang aktif: kalau dimatikan di Settings, jatuh ke tab pertama yang masih aktif
    readonly property string curTab: tab === "settings" || tab === "tray" || Settings.tabs.includes(tab)
                                     ? tab : (Settings.tabs.length > 0 ? Settings.tabs[0] : "settings")
    readonly property var activeMods: Settings.tabs.map(id => Mods.all.find(m => m.id === id)).filter(m => !!m)

    SystemClock { id: clock; precision: SystemClock.Minutes }
    Binding { target: Sys; property: "active"; value: root.expanded }
    Binding { target: UI; property: "expanded"; value: root.expanded }

    // singleton yang punya kerja latar dibangunkan sejak awal
    Component.onCompleted: {
        ScreenTime.touch(); NotifLog.touch(); Health.touch(); Cal.touch(); Hud.touch(); Notifs.touch(); Dnd.touch()
    }

    // HUD volume
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() { Hud.flash("vol", root.sink.audio.volume, root.sink.audio.muted) }
        function onMutedChanged() { Hud.flash("vol", root.sink.audio.volume, root.sink.audio.muted) }
    }

    IpcHandler {
        target: "ponarch"
        function toggle(): void {
            root.pinned = !root.pinned
            if (!root.pinned) root.open = false
        }
        function vis(): void { root.hidden = !root.hidden; if (root.hidden) { root.pinned = false; root.open = false } }
        function show(): void { root.pinned = true }
        function hide(): void { root.pinned = false; root.open = false }
        function tab(name: string): void { root.tab = name; root.pinned = true }
        function brightness(direction: string): void {
            root.stepBrightness(direction === "increment" ? 0.05 : -0.05)
        }
    }

    function stepVolume(d) {
        const a = root.sink ? root.sink.audio : null
        if (a) a.volume = Math.max(0, Math.min(1, a.volume + d))
    }
    function stepBrightness(d) {
        const cur = Hud.briLast >= 0 ? Hud.briLast / Hud.briMax : Sys.brightness
        const v = Math.max(0.01, Math.min(1, cur + d))
        Hud.flash("bri", v, false)
        Hud.briLast = Math.round(v * Hud.briMax)
        Quickshell.execDetached(["brightnessctl", "set", Math.max(1, Math.round(v * 100)) + "%"])
    }
    Timer {
        id: toastTimer
        interval: 5000
        onTriggered: root.endToast("expire")
    }
    function endToast(how) {
        toastTimer.stop()
        toastOn = false
        tActs = 0
        tn = null
        Notifs.done(how)
    }
    function openToast() {
        if (tn) {
            for (let i = 0; i < tn.actions.length; i++)
                if (tn.actions[i].identifier === "default") { tn.actions[i].invoke(); endToast("dismiss"); return }
        }
        endToast("dismiss")
        tab = "notif"
        open = true
    }
    // mode mendengarkan (daemon lain yang menampilkan popup aslinya)
    Connections {
        target: NotifLog
        function onArrived(app, summary, body, icon, de, img) {
            if (!Settings.notifToast || Dnd.on) return
            Notifs.playSoundFor(app, summary, body, de)
            if (Notifs.isScreenshot(app, summary, body, de) && !Settings.notifScreenshotToast) return
            root.tn = null; root.tActs = 0
            root.tApp = app; root.tSum = summary; root.tBody = body; root.tIcon = icon; root.tDe = de; root.tImg = img
            root.toastOn = true
            toastTimer.interval = 5000
            toastTimer.restart()
        }
    }
    // mode daemon: Ponarch menerima notifikasi langsung
    Connections {
        target: Notifs
        function onShown(n) {
            let c = 0
            for (let i = 0; i < n.actions.length; i++) if (n.actions[i].identifier !== "default") c++
            root.tn = n
            root.tActs = c
            root.tApp = n.appName; root.tSum = n.summary; root.tBody = n.body
            root.tIcon = n.appIcon; root.tDe = n.desktopEntry; root.tImg = n.image
            root.toastOn = true
            const t = n.expireTimeout > 0 ? n.expireTimeout * 1000 : (n.urgency === NotificationUrgency.Critical ? 12000 : 5000)
            toastTimer.interval = c > 0 ? Math.max(t, 8000) : t
            toastTimer.restart()
        }
    }
    Timer { id: openTimer; interval: Settings.hoverDelay; onTriggered: root.open = true }
    Timer {
        id: closeTimer
        interval: Settings.closeDelay
        onTriggered: { if (!UI.typing) root.open = false }
    }
    Connections {
        target: UI
        function onTypingChanged() {
            if (!UI.typing && !root.pinned) closeTimer.restart()
        }
    }

    PanelWindow {
        id: win
        visible: !root.hidden
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? Quickshell.screens[0]
        anchors.top: true
        implicitWidth: Math.max(480, Settings.panelWidth + 40)
        implicitHeight: Math.max(310, Settings.panelHeight + 40)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "ponarch"
        WlrLayershell.keyboardFocus: root.expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        mask: Region { item: maskBox }

        // area input statis: hanya berubah saat keadaan berganti, bukan tiap frame animasi
        Item {
            id: maskBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Settings.gap
            width: root.tw
            height: root.th
        }

        Rectangle {
            id: pill
            antialiasing: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Settings.gap
            color: Settings.pill
            Behavior on color { ColorAnimation { duration: 300 } }
            border.width: 0
            topLeftRadius: Settings.gap > 0 ? Settings.radius : 0
            topRightRadius: Settings.gap > 0 ? Settings.radius : 0
            bottomLeftRadius: Settings.radius
            bottomRightRadius: Settings.radius
            readonly property bool lyricMode: Settings.lyrics && Settings.lyricsClosed && Media.playing
                                              && Lyrics.current !== "" && !Hud.shown
            readonly property bool peek: hh.hovered && Media.playing && Settings.musicHover && !root.expanded && !Hud.shown
            width: root.tw
            height: root.th
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, Settings.radius - 1)
                color: "transparent"
                border.width: 0
                visible: Settings.mode === "glass"
            }

            HoverHandler {
                id: hh
                onHoveredChanged: {
                    if (hh.hovered) {
                        closeTimer.stop()
                        if (Settings.hoverOpen && !(Media.playing && Settings.musicHover)) openTimer.restart()
                    } else {
                        openTimer.stop()
                        if (!root.pinned) closeTimer.restart()
                    }
                }
            }
            WheelHandler {
                enabled: !root.expanded
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: e => {
                    const d = e.angleDelta.y / 120 * 0.05
                    if (d === 0) return
                    if (hh.point.position.x < pill.width / 2) root.stepBrightness(d)
                    else root.stepVolume(d)
                }
            }
            DropArea {
                anchors.fill: parent
                onDropped: drop => {
                    Shelf.add(Shelf.pathsFrom(drop.urls))
                    root.tab = "shelf"
                    root.pinned = true
                    drop.accept()
                }
            }
            TapHandler { onTapped: { if (!root.expanded && !pill.peek && !root.toasting) root.open = true } }

            // ---- closed ----
            Row {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                height: 28
                opacity: root.expanded || root.toasting || Hud.shown || pill.peek ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Item {
                    id: compactMediaSlot
                    width: pill.lyricMode ? 76 : 76
                    height: 28
                    clip: true
                    Rectangle {
                        id: compactArt
                        visible: Media.playing
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        antialiasing: true; radius: 5
                        color: "#2a2a2e"
                        clip: true
                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(128, 128); asynchronous: true
                            source: Media.player ? Media.player.trackArtUrl : ""
                        }
                    }
                    Slot { anchors.fill: parent; visible: !Media.playing; kind: Settings.leftSlot; now: clock.date }
                }
                Text {
                    width: pill.lyricMode ? 188 : 80
                    height: 28
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: "white"
                    font.pixelSize: pill.lyricMode ? 11 : 13
                    text: pill.lyricMode ? Lyrics.current : Qt.formatDateTime(clock.date, "HH:mm")
                }
                Item {
                    width: 76
                    height: 28
                    Visualizer {
                        anchors.centerIn: parent
                        visible: Media.playing && Settings.cava
                        running: Media.playing && Settings.cava && !root.expanded
                    }
                    Slot { anchors.fill: parent; visible: !Media.playing; kind: Settings.rightSlot; now: clock.date }
                }
            }

            // ---- Pomodoro di dalam island (baris kedua) ----
            Item {
                id: strip
                readonly property bool show: Settings.pomoStyle === "strip" && Pomo.ringOn && !root.expanded && !root.toasting
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 28
                height: 22
                opacity: show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Canvas {
                    id: sring
                    x: 18; anchors.verticalCenter: parent.verticalCenter
                    width: 16; height: 16
                    property real p: Pomo.progress
                    readonly property color col: Pomo.mode === "short" || Pomo.mode === "long" ? "#43c5a0" : Settings.accentColor
                    onPChanged: requestPaint()
                    onColChanged: requestPaint()
                    onVisibleChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d")
                        c.reset()
                        c.lineWidth = 2.5
                        c.lineCap = "round"
                        c.strokeStyle = "#33ffffff"
                        c.beginPath(); c.arc(8, 8, 6, 0, Math.PI * 2); c.stroke()
                        if (p > 0.005) {
                            c.strokeStyle = col
                            c.beginPath(); c.arc(8, 8, 6, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p); c.stroke()
                        }
                    }
                }
                Text {
                    anchors.left: sring.right; anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: Settings.soft; font.pixelSize: 12
                    text: Pomo.modeName + (Pomo.running ? "" : " · jeda")
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: "white"; font.pixelSize: 12; font.bold: true
                    text: Pomo.label
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.tab = "pomo"; root.open = true }
                }
            }

            // ---- cincin Pomodoro ----
            Canvas {
                id: ring
                anchors.fill: parent
                visible: Settings.pomoStyle === "ring" && Pomo.ringOn
                property real p: Pomo.progress
                onPChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onVisibleChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    if (width < 4 || height < 4) return
                    const o = 1.5, w = width - 2 * o, h = height - 2 * o
                    const rt = Math.min(pill.topLeftRadius, h / 2, w / 2), rb = Math.min(pill.bottomLeftRadius, h / 2, w / 2)
                    const per = (w - 2 * rt) + (h - rt - rb) + (w - 2 * rb) + (h - rt - rb) + Math.PI / 2 * (2 * rt + 2 * rb)
                    function path() {
                        ctx.beginPath()
                        ctx.moveTo(o + w / 2, o)
                        ctx.lineTo(o + w - rt, o)
                        if (rt > 0) ctx.arc(o + w - rt, o + rt, rt, -Math.PI / 2, 0)
                        ctx.lineTo(o + w, o + h - rb)
                        if (rb > 0) ctx.arc(o + w - rb, o + h - rb, rb, 0, Math.PI / 2)
                        ctx.lineTo(o + rb, o + h)
                        if (rb > 0) ctx.arc(o + rb, o + h - rb, rb, Math.PI / 2, Math.PI)
                        ctx.lineTo(o, o + rt)
                        if (rt > 0) ctx.arc(o + rt, o + rt, rt, Math.PI, Math.PI * 1.5)
                        ctx.lineTo(o + w / 2, o)
                    }
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.strokeStyle = "#ffffff22"
                    path(); ctx.stroke()
                    if (p > 0.002) {
                        ctx.strokeStyle = Pomo.mode === "focus" || Pomo.mode === "timer" || Pomo.isWatch ? Settings.accentColor : "#43c5a0"
                        ctx.setLineDash([per * p, per * 2])
                        path(); ctx.stroke()
                    }
                }
            }

            // ---- peek musik (hover) ----
            // area kosong di peek ikut membuka notch (tombol & judul di atasnya tetap bekerja sendiri)
            MouseArea {
                anchors.fill: parent
                enabled: pill.peek && !root.toasting
                onClicked: root.open = true
            }
            Row {
                anchors.centerIn: parent
                spacing: 8
                opacity: pill.peek && !root.toasting ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18; height: 18; antialiasing: true; radius: 5; color: "#2a2a2e"; clip: true
                    Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(128, 128); asynchronous: true; source: Media.player ? Media.player.trackArtUrl : "" }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 170
                    elide: Text.ElideRight
                    color: "white"; font.pixelSize: 11
                    text: Media.player ? (Media.player.trackTitle + (Media.player.trackArtist ? " · " + Media.player.trackArtist : "")) : ""
                    MouseArea { anchors.fill: parent; onClicked: root.open = true }
                }
                Repeater {
                    model: ["⏮", "t", "⏭"]
                    Text {
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"; font.pixelSize: 14
                        text: modelData === "t" ? (Media.player && Media.player.isPlaying ? "⏸" : "▶") : modelData
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -3
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const p = Media.player
                                if (!p) return
                                if (modelData === "⏮") p.previous()
                                else if (modelData === "⏭") p.next()
                                else p.togglePlaying()
                            }
                        }
                    }
                }
            }

            // ---- popup notifikasi ----
            Item {
                anchors.fill: parent
                opacity: root.toasting ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Item { id: tHead; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 56 }
                NotifIcon {
                    id: nIcon
                    anchors.left: parent.left; anchors.leftMargin: 14
                    anchors.verticalCenter: tHead.verticalCenter
                    size: 30
                    app: root.tApp; icon: root.tIcon; de: root.tDe; img: root.tImg
                }
                Column {
                    anchors.left: nIcon.right; anchors.leftMargin: 12
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.verticalCenter: tHead.verticalCenter
                    spacing: 1
                    Text { width: parent.width; elide: Text.ElideRight; color: Settings.dim; font.pixelSize: 10; text: root.tApp }
                    Text { width: parent.width; elide: Text.ElideRight; color: "white"; font.pixelSize: 12; font.bold: true; text: root.tSum }
                    Text { width: parent.width; elide: Text.ElideRight; color: Settings.soft; font.pixelSize: 11; text: root.tBody.replace(/\n/g, " ") }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openToast()
                }
                Row {
                    visible: root.tActs > 0
                    anchors.left: parent.left; anchors.leftMargin: 14
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    spacing: 6
                    Repeater {
                        model: root.tn ? root.tn.actions : []
                        Tile {
                            required property var modelData
                            required property int index
                            visible: modelData.identifier !== "default" && index < 4
                            width: (parent.width - 18) / 3
                            implicitHeight: 22
                            label: modelData.text
                            onClicked: { modelData.invoke(); root.endToast("dismiss") }
                        }
                    }
                }
            }

            // ---- HUD ----
            Row {
                anchors.centerIn: parent
                spacing: 8
                opacity: Hud.shown && !root.expanded && !root.toasting ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    name: Hud.kind === "bri" ? "brightness" : (Hud.muted || Hud.value === 0 ? "audio-muted" : "audio")
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 150; height: 5; antialiasing: true; radius: 2.5; color: "#333333"
                    Rectangle {
                        height: parent.height; antialiasing: true; radius: 2.5; color: Settings.accentColor
                        width: parent.width * (Hud.muted ? 0 : Hud.value)
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Settings.soft; font.pixelSize: 11
                    text: Math.round(Hud.value * 100)
                }
            }

            // ---- expanded ----
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                // top bar: tabs | clock | battery + gear
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    spacing: 2

                    ListView {
                        id: tabBar
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        orientation: ListView.Horizontal
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.activeMods
                        onCountChanged: sync()
                        function sync() {
                            const i = root.activeMods.findIndex(m => m.id === root.curTab)
                            if (i >= 0) positionViewAtIndex(i, ListView.Contain)
                        }
                        Connections { target: root; function onCurTabChanged() { tabBar.sync() } }
                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: e => { tabBar.contentX = Math.max(0, Math.min(tabBar.contentWidth - tabBar.width,
                                                  tabBar.contentX - (e.angleDelta.y + e.angleDelta.x) / 2)) }
                        }
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool current: root.curTab === modelData.id
                            width: current ? tabRow.implicitWidth + 14 : 26
                            height: 22
                            antialiasing: true; radius: 9
                            color: current ? Settings.accentSoft : "transparent"
                            Behavior on width { NumberAnimation { duration: 120 } }
                            Row {
                                id: tabRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    color: parent.parent.current ? "white" : Settings.dim
                                    font.pixelSize: 13
                                    text: parent.parent.modelData.icon
                                }
                                Text {
                                    visible: parent.parent.current
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"
                                    font.pixelSize: 11
                                    text: parent.parent.modelData.name
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.tab = parent.modelData.id
                            }
                        }
                    }

                    Rectangle {
                        id: trayBtn
                        readonly property int n: SystemTray.items.values.filter(i => i.status > 0).length
                        visible: n > 0
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 22
                        antialiasing: true; radius: 9
                        color: root.curTab === "tray" ? Settings.accentSoft : "transparent"
                        Row {
                            anchors.centerIn: parent
                            spacing: 3
                            Text { color: root.curTab === "tray" ? "white" : Settings.dim; font.pixelSize: 13; text: "▣" }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: Settings.soft; font.pixelSize: 10; text: trayBtn.n
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tab = "tray"
                        }
                    }
                    Icon {
                        visible: !!UPower.displayDevice && UPower.displayDevice.isPresent
                        width: 15
                        height: 15
                        name: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging
                              ? "battery-charging" : "battery"
                    }
                    Text {
                        visible: !!UPower.displayDevice && UPower.displayDevice.isPresent
                        color: Settings.soft
                        font.pixelSize: 11
                        text: Math.round((UPower.displayDevice ? UPower.displayDevice.percentage : 0) * 100) + "%"
                    }
                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 22
                        antialiasing: true; radius: 9
                        color: root.curTab === "settings" ? Settings.accentSoft : "transparent"
                        Text {
                            anchors.centerIn: parent
                            color: root.curTab === "settings" ? "white" : Settings.dim
                            font.pixelSize: 13
                            text: "⚙"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tab = "settings"
                        }
                    }
                }

                // hanya tab aktif yang dimuat; saat notch menutup semuanya dibuang
                Loader {
                    id: content
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.expanded
                    source: Mods.file(root.curTab)
                    onLoaded: {
                        item.width = Qt.binding(() => content.width)
                        item.height = Qt.binding(() => content.height)
                    }
                }
            }
        }
    }
}
