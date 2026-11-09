pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Ponarch sebagai daemon notifikasi (pengganti swaync/mako/dunst): menerima notifikasi langsung dari D-Bus,
// lengkap dengan ikon, gambar, dan tombol aksi. Hanya satu daemon yang boleh aktif dalam satu waktu.
Singleton {
    id: root

    property var current: null          // notifikasi yang sedang tampil sebagai popup
    signal shown(var n)

    function touch() { }

    function isScreenshot(app, summary, body, de) {
        const text = (app + " " + summary + " " + body + " " + de).toLowerCase()
        return text.indexOf("screenshot") >= 0 || text.indexOf("screen shot") >= 0
            || text.indexOf("capture") >= 0 || text.indexOf("copied to clipboard") >= 0
    }

    function soundId(app, summary, body, de) {
        const text = (app + " " + summary + " " + body + " " + de).toLowerCase()
        if (isScreenshot(app, summary, body, de)) return "complete"
        if (text.indexOf("error") >= 0 || text.indexOf("failed") >= 0
                || text.indexOf("gagal") >= 0) return "dialog-error"
        if (text.indexOf("warning") >= 0 || text.indexOf("peringatan") >= 0) return "dialog-warning"
        return "message-new-instant"
    }

    function playSoundFor(app, summary, body, de) {
        if (!Settings.notifSound) return
        const id = soundId(app || "", summary || "", body || "", de || "")
        Quickshell.execDetached(["sh", "-c",
            "if command -v canberra-gtk-play >/dev/null 2>&1; then " +
            "canberra-gtk-play -i " + id + " -d Ponarch >/dev/null 2>&1; " +
            "elif command -v paplay >/dev/null 2>&1; then " +
            "paplay /usr/share/sounds/freedesktop/stereo/" + id + ".oga >/dev/null 2>&1; fi"])
    }

    function incoming(n) {
        n.tracked = true
        NotifLog.record(n.appName, n.summary, n.body, n.appIcon, n.desktopEntry, n.image)
        if (Settings.dnd || !Settings.notifToast) { n.expire(); return }
        playSoundFor(n.appName, n.summary, n.body, n.desktopEntry)
        if (isScreenshot(n.appName, n.summary, n.body, n.desktopEntry) && !Settings.notifScreenshotToast) {
            n.expire()
            return
        }
        if (current && current !== n) current.expire()
        current = n
        shown(n)
    }

    // how: "dismiss" (ditutup pengguna) | "expire" (waktu habis)
    function done(how) {
        const n = current
        current = null
        if (!n) return
        if (how === "dismiss") n.dismiss()
        else n.expire()
    }

    LazyLoader {
        active: Settings.notifDaemon
        NotificationServer {
            actionsSupported: true
            imageSupported: true
            bodyMarkupSupported: false
            persistenceSupported: true
            onNotification: n => root.incoming(n)
        }
    }
}
