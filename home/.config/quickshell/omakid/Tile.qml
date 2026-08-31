import QtQuick

Item {
    id: tile
    property string tileId
    property string iconSrc
    property string label
    property color foreground: "#ffffff"

    signal entered()
    signal activated()

    width: 300; height: 380

    Column {
        anchors.centerIn: parent
        spacing: 24

        Rectangle {
            width: 260; height: 260; radius: 40
            color: "transparent"
            border.width: ma.containsMouse ? 6 : 0
            border.color: tile.foreground
            scale: ma.containsMouse ? 1.06 : 1.0
            Behavior on scale { NumberAnimation { duration: 140 } }

            Image {
                anchors.fill: parent
                source: tile.iconSrc
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.label
            color: tile.foreground
            font { pixelSize: 40; weight: Font.DemiBold }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.entered()
        onClicked: tile.activated()
    }
}
