import QtQuick

Rectangle {
    id: f
    property alias text: inp.text
    property string placeholder: ""
    property bool password: false
    signal accepted(string value)
    implicitHeight: 30
    antialiasing: true; radius: 10
    color: Settings.tile

    function clear() { inp.text = "" }
    function focusIn() { inp.forceActiveFocus() }

    TextInput {
        id: inp
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        color: "white"
        font.pixelSize: 12
        clip: true
        selectByMouse: true
        echoMode: f.password ? TextInput.Password : TextInput.Normal
        onAccepted: f.accepted(text)
        onActiveFocusChanged: UI.focusDelta(activeFocus)
        Keys.onEscapePressed: inp.focus = false

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: inp.text === "" && !inp.activeFocus
            color: Settings.faint
            font.pixelSize: 12
            text: f.placeholder
        }
    }
    Component.onDestruction: { if (inp.activeFocus) UI.focusDelta(false) }
}
