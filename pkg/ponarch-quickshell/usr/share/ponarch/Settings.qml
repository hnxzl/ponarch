pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // look
    property alias mode: adapter.mode
    property alias accent: adapter.accent
    property alias accentFromWall: adapter.accentFromWall
    property alias glassTint: adapter.glassTint
    property alias wallpaper: adapter.wallpaper
    property alias glassOpacity: adapter.glassOpacity
    property alias radius: adapter.radius
    property alias gap: adapter.gap
    property alias notchWidth: adapter.notchWidth
    property alias panelWidth: adapter.panelWidth
    property alias panelHeight: adapter.panelHeight
    // behaviour
    property alias hoverOpen: adapter.hoverOpen
    property alias hoverDelay: adapter.hoverDelay
    property alias closeDelay: adapter.closeDelay
    property alias leftSlot: adapter.leftSlot
    property alias rightSlot: adapter.rightSlot
    property alias hud: adapter.hud
    property alias notifToast: adapter.notifToast
    property alias notifDaemon: adapter.notifDaemon
    property alias notifSound: adapter.notifSound
    property alias notifScreenshotToast: adapter.notifScreenshotToast
    property alias dnd: adapter.dnd
    property alias musicHover: adapter.musicHover
    property alias pomoStyle: adapter.pomoStyle
    property alias homeCal: adapter.homeCal
    property alias sysDetail: adapter.sysDetail
    property alias cava: adapter.cava
    property alias weatherDashboard: adapter.weatherDashboard
    property alias lyrics: adapter.lyrics
    property alias lyricsClosed: adapter.lyricsClosed
    property alias notifLog: adapter.notifLog
    // content
    property alias tabs: adapter.tabs
    property alias launchers: adapter.launchers
    property alias widgets: adapter.widgets
    property alias calendars: adapter.calendars
    property alias calRemind: adapter.calRemind
    // location (weather + prayer times)
    property alias autoLocation: adapter.autoLocation
    property alias city: adapter.city
    property alias lat: adapter.lat
    property alias lon: adapter.lon
    property alias prayerMethod: adapter.prayerMethod
    // pomodoro / health / day
    property alias focusMin: adapter.focusMin
    property alias shortMin: adapter.shortMin
    property alias longMin: adapter.longMin
    property alias eyeBreak: adapter.eyeBreak
    property alias waterEvery: adapter.waterEvery
    property alias wakeHour: adapter.wakeHour
    property alias bedHour: adapter.bedHour
    // AI
    property alias aiProvider: adapter.aiProvider
    property alias transEngine: adapter.transEngine
    property alias aiModel: adapter.aiModel
    property alias aiBase: adapter.aiBase
    property alias aiKey: adapter.aiKey

    readonly property color accentColor: accentFromWall && Wall.ready ? Wall.accent : accent
    readonly property color accentSoft: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.55)
    readonly property real glassAlpha: Math.min(0.48, Math.max(0.24, 0.16 + glassOpacity * 0.36))
    readonly property color pill: mode === "glass" ? (glassTint === "app" && AppTint.ready ? Qt.rgba(AppTint.tint.r, AppTint.tint.g, AppTint.tint.b, glassAlpha) : (glassTint === "wallpaper" && Wall.ready ? Qt.rgba(Wall.tint.r, Wall.tint.g, Wall.tint.b, glassAlpha) : Qt.rgba(0.28, 0.36, 0.50, glassAlpha)))
                                : mode === "color" ? Qt.darker(accentColor, 2.6)
                                : "black"
    // kotak: gelap transparan di glass/color supaya teks tetap terbaca di atas wallpaper terang
    readonly property color tile: mode === "black" ? "#1c1c1f" : (mode === "glass" ? Qt.rgba(0.72, 0.82, 0.98, 0.13) : Qt.rgba(0, 0, 0, 0.32))
    // teks redup: lebih terang di glass/color agar kontras
    readonly property color dim: mode === "black" ? "#aaaaaa" : "#dfe3e8"
    readonly property color soft: mode === "black" ? "#cccccc" : "#eef0f3"
    readonly property color faint: mode === "black" ? "#777777" : "#b4b9c0"

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.config/ponarch"])

    FileView {
        path: Quickshell.env("HOME") + "/.config/ponarch/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        adapter: JsonAdapter {
            id: adapter
            property string mode: "black"
            property string accent: "#5b7cff"
            // ikut wallpaper: aksen dan/atau warna glass; wallpaper "" = ~/.config/hypr/current_wallpaper
            property bool accentFromWall: false
            // glassTint: normal | wallpaper (dari wallpaper) | app (mengikuti aplikasi yang dibuka)
            property string glassTint: "normal"
            property string wallpaper: ""
            property real glassOpacity: 0.55
            property int radius: 22
            property int gap: 0
            property int notchWidth: 232
            property int panelWidth: 560
            property int panelHeight: 420
            property bool hoverOpen: true
            property int hoverDelay: 120
            property int closeDelay: 350
            property string leftSlot: "workspaces"
            property string rightSlot: "battery"
            property bool hud: true
            property bool notifToast: true
            property bool notifSound: true
            // notifDaemon: Ponarch menjadi daemon notifikasi (matikan swaync/mako/dunst). false = hanya mendengarkan daemon lain.
            property bool notifDaemon: true
            property bool notifScreenshotToast: false
            property bool dnd: false
            property bool musicHover: true
            // pomoStyle: strip (pil kecil di bawah notch) | ring (garis di sekeliling) | off
            property string pomoStyle: "strip"
            // sysDetail: tab System tampil angka detail (mis. 9.2 / 15.6 GB) alih-alih bar
            property bool sysDetail: false
            // homeCal: week (7 hari) | month (kotak sebulan) di tab Home
            property string homeCal: "week"
            property bool cava: true
            property bool weatherDashboard: true
            property bool lyrics: false
            property bool lyricsClosed: false
            property bool notifLog: true
            property var tabs: ["home", "dash", "control", "net", "todo", "notes", "pomo", "weather", "prayer",
                                "health", "day", "cal", "ai", "trans", "shelf", "notif", "gh", "screen", "system", "buddy"]

            // autoLocation: ikuti lokasi laptop (lewat IP). false = pakai city/lat/lon di bawah.
            property bool autoLocation: true
            property string city: "Jakarta"
            property real lat: -6.2088
            property real lon: 106.8456
            property int prayerMethod: 20

            property int focusMin: 25
            property int shortMin: 5
            property int longMin: 15
            property bool eyeBreak: false
            property int waterEvery: 0
            property int wakeHour: 7
            property int bedHour: 23

            // AI: aiProvider = claude | gemini | openai | ollama. Key sebaiknya lewat env PONARCH_AI_KEY (ponarch.env).
            property string aiProvider: "claude"
            // transEngine: free (tanpa kunci: Google gtx, cadangan MyMemory) | ai (pakai provider AI di atas)
            property string transEngine: "free"
            property string aiModel: ""
            property string aiBase: ""
            property string aiKey: ""

            // Link iCal (Google Calendar: "alamat rahasia dalam format iCal"). { "name": "Kerja", "url": "https://..." }
            property var calendars: []
            property int calRemind: 10

            // Tombol di tab Control. Ubah/tambah sesukamu: { "label": "...", "cmd": "perintah shell" }
            property var launchers: [
                { label: "Apps",      cmd: "pkill rofi || rofi -show drun || wofi --show drun || fuzzel" },
                { label: "Files",     cmd: "xdg-open $HOME" },
                { label: "Term",      cmd: "xdg-terminal-exec || kitty || foot || alacritty || wezterm" },
                { label: "Browser",   cmd: "xdg-open https://" },
                { label: "Lock",      cmd: "loginctl lock-session" },
                { label: "LocalSend", cmd: "ponarch localsend" }
            ]

            // Baris info di tab System. Contoh: { "label": "Updates", "exec": "checkupdates | wc -l", "interval": 600 }
            property var widgets: []
        }
    }
}
