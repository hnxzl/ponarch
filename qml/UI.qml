pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // jumlah field teks yang sedang fokus; > 0 menahan notch tetap terbuka
    property int focusCount: 0
    readonly property bool typing: focusCount > 0
    property bool expanded: false

    function focusDelta(on) { focusCount = Math.max(0, focusCount + (on ? 1 : -1)) }
}
