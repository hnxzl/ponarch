import QtQuick
import Quickshell

// Ikon aplikasi untuk notifikasi; kalau tidak ketemu, tampil huruf pertama nama aplikasi.
Item {
    id: ni
    property string app: ""
    property string icon: ""
    property string de: ""
    property string img: ""
    property int size: 28
    width: size
    height: size

    readonly property string src: {
        const names = [img, icon, de, de.toLowerCase().replace(/\.desktop$/, ""), app.toLowerCase().replace(/\s+/g, "-")]
        for (let i = 0; i < names.length; i++) {
            const n = names[i]
            if (!n) continue
            if (n.indexOf("file://") === 0 || n.indexOf("image://") === 0) return n
            if (n.charAt(0) === "/") return "file://" + n
            const p = Quickshell.iconPath(n, true)
            if (p) return p.charAt(0) === "/" ? "file://" + p : p
        }
        return ""
    }

    Image {
        id: pic
        anchors.fill: parent
        source: ni.src
        sourceSize: Qt.size(ni.size * 2, ni.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: status === Image.Ready
    }
    Rectangle {
        anchors.fill: parent
        visible: pic.status !== Image.Ready
        antialiasing: true; radius: ni.size / 4
        color: Settings.accentSoft
        Text {
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: ni.size * 0.5
            font.bold: true
            text: (ni.app || "?").charAt(0).toUpperCase()
        }
    }
}
