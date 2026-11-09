pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var all: [
        { id: "home",    icon: "⌂", name: "Home",       file: "Home.qml" },
        { id: "dash",    icon: "▥", name: "Dashboard",  file: "DashTab.qml" },
        { id: "control", icon: "☰", name: "Control",    file: "Control.qml" },
        { id: "net",     icon: "⇅", name: "Wi-Fi & BT", file: "NetTab.qml" },
        { id: "todo",    icon: "☑", name: "Todo",       file: "TodoTab.qml" },
        { id: "notes",   icon: "✎", name: "Notes",      file: "NotesTab.qml" },
        { id: "pomo",    icon: "◔", name: "Pomodoro",   file: "PomoTab.qml" },
        { id: "weather", icon: "W",  name: "Weather",    file: "WeatherTab.qml" },
        { id: "prayer",  icon: "☪", name: "Prayer",     file: "PrayerTab.qml" },
        { id: "health",  icon: "♥", name: "Health",     file: "HealthTab.qml" },
        { id: "day",     icon: "◐", name: "Day",        file: "DayTab.qml" },
        { id: "cal",     icon: "▦", name: "Calendar",   file: "CalTab.qml" },
        { id: "ai",      icon: "✦", name: "AI Chat",    file: "AiTab.qml" },
        { id: "trans",   icon: "⇄", name: "Translate",  file: "TransTab.qml" },
        { id: "shelf",   icon: "⇩", name: "Shelf",      file: "ShelfTab.qml" },
        { id: "notif",   icon: "✉", name: "Notifs",     file: "NotifTab.qml" },
        { id: "gh",      icon: "◈", name: "GitHub",     file: "GitTab.qml" },
        { id: "screen",  icon: "◷", name: "Screen",     file: "ScreenTab.qml" },
        { id: "system",  icon: "▤", name: "System",     file: "SystemTab.qml" },
        { id: "buddy",   icon: "☻", name: "Buddy",      file: "BuddyTab.qml" }
    ]

    function file(id) {
        if (id === "settings") return "SettingsTab.qml"
        if (id === "tray") return "TrayTab.qml"
        const m = all.find(x => x.id === id)
        return m ? m.file : "Home.qml"
    }
}
