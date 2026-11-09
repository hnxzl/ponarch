import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: ct
    spacing: 6

    Component.onCompleted: Cal.ensure()

    function dayLabel(ms) {
        const d = new Date(ms)
        const t = new Date()
        const a = new Date(t.getFullYear(), t.getMonth(), t.getDate()).getTime()
        const b = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
        const diff = Math.round((b - a) / 86400000)
        if (diff === 0) return "Hari ini"
        if (diff === 1) return "Besok"
        return Qt.formatDate(d, "ddd d MMM")
    }

    // tambah acara (Google Calendar)
    property int dayOff: 0
    property int durIdx: 1
    readonly property var durs: [{ l: "30m", m: 30 }, { l: "1j", m: 60 }, { l: "2j", m: 120 }, { l: "All", m: 0 }]

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function ymd(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
    function submit() {
        const t = /^(\d{1,2})[:.]?(\d{2})$/.exec(timeF.text.trim())
        const d = new Date()
        d.setDate(d.getDate() + dayOff)
        const dur = durs[durIdx]
        if (dur.m === 0) { Cal.addEvent(titleF.text, ymd(d) + "T00:00", ymd(d) + "T00:00", true) }
        else {
            const h = t ? Math.min(23, +t[1]) : d.getHours() + 1
            const mi = t ? Math.min(59, +t[2]) : 0
            const s = new Date(d.getFullYear(), d.getMonth(), d.getDate(), h, mi)
            const e = new Date(s.getTime() + dur.m * 60000)
            Cal.addEvent(titleF.text, ymd(s) + "T" + pad(s.getHours()) + ":" + pad(s.getMinutes()),
                         ymd(e) + "T" + pad(e.getHours()) + ":" + pad(e.getMinutes()), false)
        }
        titleF.clear()
    }

    RowLayout {
        visible: Cal.gOn
        Layout.fillWidth: true
        spacing: 6
        Field { id: titleF; Layout.fillWidth: true; placeholder: "＋ Acara"; onAccepted: ct.submit() }
        Tile { Layout.preferredWidth: 58; implicitHeight: 30
               label: ct.dayOff === 0 ? "Hari ini" : ct.dayOff === 1 ? "Besok" : "+" + ct.dayOff
               onClicked: ct.dayOff = (ct.dayOff + 1) % 8 }
        Field { id: timeF; Layout.preferredWidth: 52; visible: ct.durs[ct.durIdx].m !== 0; placeholder: "HH:MM"; onAccepted: ct.submit() }
        Tile { Layout.preferredWidth: 38; implicitHeight: 30; label: ct.durs[ct.durIdx].l
               onClicked: ct.durIdx = (ct.durIdx + 1) % ct.durs.length }
        Tile { Layout.preferredWidth: 34; implicitHeight: 30; label: Cal.loading ? "…" : "＋"; onClicked: ct.submit() }
    }
    Text { visible: Cal.gError !== ""; color: "#ff7a7a"; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight; text: Cal.gError }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Field {
            id: url
            visible: !Cal.configured
            Layout.fillWidth: true
            placeholder: "Link iCal"
            onAccepted: value => { Cal.addCal(value); url.clear() }
        }
        Text { visible: Cal.configured; Layout.fillWidth: true; color: Settings.dim; font.pixelSize: 11; text: Cal.gOn ? "Google ✓" : "iCal ✓" }
        Tile { visible: Cal.configured; Layout.preferredWidth: 60; implicitHeight: 26; label: Cal.loading ? "…" : "Refresh"; onClicked: { Cal.fetchedAt = 0; Cal.refresh() } }
        Tile { visible: Cal.configured && !Cal.gOn; Layout.preferredWidth: 60; implicitHeight: 26; label: "Ganti"; onClicked: Settings.calendars = [] }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: Cal.events
        delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool now: modelData.start <= Date.now() && modelData.end >= Date.now()
            width: list.width
            height: 38
            antialiasing: true; radius: 8
            color: now ? Settings.accentSoft : Settings.tile
            Text {
                id: day
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.top: parent.top; anchors.topMargin: 5
                color: Settings.dim; font.pixelSize: 10
                text: ct.dayLabel(modelData.start) + (modelData.allDay ? " · seharian"
                      : " · " + Qt.formatTime(new Date(modelData.start), "HH:mm") + "–" + Qt.formatTime(new Date(modelData.end), "HH:mm"))
            }
            Text {
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.bottom: parent.bottom; anchors.bottomMargin: 5
                elide: Text.ElideRight; color: "white"; font.pixelSize: 12
                text: modelData.title + (modelData.loc ? "  ·  " + modelData.loc : "")
            }
        }
        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            color: Settings.faint; font.pixelSize: 12
            text: Cal.loading ? "…" : "—"
        }
    }
}
