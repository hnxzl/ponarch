import QtQuick

Image {
    property string name: ""
    source: name === "" ? "" : Qt.resolvedUrl("icons/" + name + ".svg")
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
    smooth: false
    mipmap: false
}
