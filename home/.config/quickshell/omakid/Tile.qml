import QtQuick

FocusScope {
    id: tile
    property string tileId
    property string iconSrc
    property string label
    property color foreground: "#1F1B24"
    property bool reducedMotion: false
    signal entered()
    signal activated()

    width: 320
    height: 250
    activeFocusOnTab: true

    Rectangle {
        id: focusSurface
        anchors.fill: parent
        radius: 28
        color: "transparent"
        border.width: mouse.containsMouse || tile.activeFocus ? 6 : 0
        border.color: tile.foreground
        scale: mouse.containsMouse || tile.activeFocus ? 1.035 : 1.0

        Behavior on scale {
            enabled: !tile.reducedMotion
            NumberAnimation { duration: 140; easing.type: Easing.OutQuart }
        }

        Column {
            anchors.centerIn: parent
            spacing: 10

            Image {
                width: 196
                height: 176
                anchors.horizontalCenter: parent.horizontalCenter
                source: tile.iconSrc
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.label
                color: tile.foreground
                font.family: "Noto Sans"
                font.pixelSize: 32
                font.weight: Font.DemiBold
            }
        }
    }

    Keys.onReturnPressed: tile.activated()
    Keys.onSpacePressed: tile.activated()
    onActiveFocusChanged: if (activeFocus) tile.entered()

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.entered()
        onClicked: {
            tile.forceActiveFocus()
            tile.activated()
        }
    }
}
