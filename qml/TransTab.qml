import QtQuick
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: tr
    spacing: 6

    readonly property var langs: ["Auto", "Indonesian", "English", "Japanese", "Korean", "Chinese", "Arabic",
                                  "Spanish", "French", "German", "Javanese"]
    property int src: 0
    property int dst: 2

    readonly property var codes: ["auto", "id", "en", "ja", "ko", "zh-CN", "ar", "es", "fr", "de", "jv"]
    property string pending: ""
    readonly property bool working: gp.running || mp.running

    function show(s) { output.text = s }

    function go() {
        const t = input.text.trim()
        if (t === "" || working) return
        output.text = "…"
        pending = t
        gp.command = ["curl", "-s", "-m", "15", "--get", "--data-urlencode", "q=" + t,
                      "https://translate.googleapis.com/translate_a/single?client=gtx&sl=" + codes[src] + "&tl=" + codes[dst] + "&dt=t"]
        gp.running = true
    }
    function fallback() {
        mp.command = ["curl", "-s", "-m", "15", "--get", "--data-urlencode", "q=" + pending,
                      "--data-urlencode", "langpair=" + (src === 0 ? "Autodetect" : codes[src]) + "|" + codes[dst],
                      "https://api.mymemory.translated.net/get"]
        mp.running = true
    }

    Process {
        id: gp
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    const out = j[0].map(x => x[0] || "").join("")
                    if (out.trim() === "") throw new Error("kosong")
                    tr.show(out)
                } catch (e) { tr.fallback() }
            }
        }
    }
    Process {
        id: mp
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    const out = j.responseData.translatedText
                    if (!out) throw new Error("kosong")
                    tr.show(out)
                } catch (e) { tr.show("⚠ Gagal menerjemahkan (cek koneksi internet)") }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Tile { Layout.preferredWidth: 80; implicitHeight: 26; label: tr.langs[tr.src]
               onClicked: tr.src = (tr.src + 1) % tr.langs.length }
        Text {
            color: "white"; font.pixelSize: 16; text: "⇄"
            MouseArea {
                anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                onClicked: { if (tr.src > 0) { const s = tr.src; tr.src = tr.dst; tr.dst = s } }
            }
        }
        Tile { Layout.preferredWidth: 80; implicitHeight: 26; label: tr.langs[tr.dst]
               onClicked: tr.dst = tr.dst >= tr.langs.length - 1 ? 1 : tr.dst + 1 }
        Item { Layout.fillWidth: true }
        Tile { Layout.preferredWidth: 76; implicitHeight: 26; label: tr.working ? "…" : "Translate"; active: true; onClicked: tr.go() }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8
        Area {
            id: input
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10
            placeholder: "Teks"
            onSubmit: tr.go()
        }
        Area {
            id: output
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 10
            readOnly: true
            placeholder: ""
        }
    }
}
