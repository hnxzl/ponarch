import QtQuick

// Kotak teks banyak baris. Ctrl+Enter memicu submit().
Rectangle {
    id: a
    property alias text: ed.text
    property string placeholder: ""
    property bool readOnly: false
    signal edited()
    signal submit()
    antialiasing: true; radius: 10
    color: Settings.tile
    clip: true

    function focusIn() { ed.forceActiveFocus() }

    Flickable {
        id: fl
        anchors.fill: parent
        anchors.margins: 8
        contentWidth: width
        contentHeight: ed.paintedHeight + 4
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        TextEdit {
            id: ed
            width: fl.width
            color: "white"
            font.pixelSize: 12
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            readOnly: a.readOnly
            onTextChanged: { if (activeFocus) a.edited() }
            onActiveFocusChanged: UI.focusDelta(activeFocus)
            onCursorRectangleChanged: {
                if (cursorRectangle.y < fl.contentY) fl.contentY = cursorRectangle.y
                else if (cursorRectangle.y + cursorRectangle.height > fl.contentY + fl.height)
                    fl.contentY = cursorRectangle.y + cursorRectangle.height - fl.height
            }
            Keys.onEscapePressed: ed.focus = false
            Keys.onPressed: event => {
                if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                    a.submit()
                    event.accepted = true
                }
            }
        }
    }
    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 8
        visible: ed.text === "" && !ed.activeFocus
        color: Settings.faint
        font.pixelSize: 12
        text: a.placeholder
    }
    Component.onDestruction: { if (ed.activeFocus) UI.focusDelta(false) }
}
