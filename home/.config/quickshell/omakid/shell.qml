import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    property string mode: Quickshell.env("OMAKID_FIRST_RUN") === "1" ? "identity-colour" : "home"
    property string lang: "en"
    property var tiles: []
    property var colours: []
    property var avatars: []
    property string colourId: "blue-light"
    property color desktopColour: "#A8D8F0"
    property color foreground: "#1F1B24"
    property string avatar: "orca"
    property string pendingExec: ""

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string stateDir: homeDir + "/.local/state/omakid"
    readonly property string assets: Quickshell.env("OMAKID_ASSETS") || "/usr/share/omarchy/shell/omakid/assets"
    readonly property bool reducedMotion: Quickshell.env("OMAKID_REDUCED_MOTION") === "1"

    function applyColour() {
        for (let i = 0; i < colours.length; i++) {
            if (colours[i].id === colourId) {
                desktopColour = colours[i].colour
                foreground = colours[i].text
                return
            }
        }
    }

    function speak(clip) {
        speaker.running = false
        speaker.command = ["paplay", assets + "/voice/" + lang + "/" + clip + ".wav"]
        speaker.running = true
    }

    function setLanguage(next) {
        lang = next
        Quickshell.execDetached(["omakid-set-language", next])
    }

    function launch(command) {
        pendingExec = command
        mode = "hidden"
        launchTimer.restart()
    }

    function chooseColour(choice) {
        colourId = choice.id
        desktopColour = choice.colour
        foreground = choice.text
        Quickshell.execDetached(["omakid-set-identity", "colour", choice.id])
        identityAdvance.restart()
    }

    function chooseAvatar(choice) {
        avatar = choice.id
        Quickshell.execDetached(["omakid-set-identity", "avatar", choice.id])
        identityDone.restart()
    }

    IpcHandler {
        target: "omakid"
        function home(): string { root.mode = "home"; return "ok" }
        function identity(): string { root.mode = "identity-colour"; return "ok" }
        function hide(): string { root.mode = "hidden"; return "ok" }
        function ping(): string { return "ok" }
    }

    FileView {
        path: root.stateDir + "/lang"
        watchChanges: true
        onLoaded: root.lang = text().trim() === "fr" ? "fr" : "en"
        onFileChanged: reload()
    }

    FileView {
        path: root.homeDir + "/.config/omakid/tiles.json"
        watchChanges: true
        onLoaded: {
            try { root.tiles = JSON.parse(text()).tiles }
            catch (error) { console.error("Omakid tiles.json is invalid:", error) }
        }
        onFileChanged: reload()
    }

    FileView {
        path: root.homeDir + "/.config/omakid/identity.json"
        watchChanges: true
        onLoaded: {
            try {
                const identity = JSON.parse(text())
                root.colours = identity.colours
                root.avatars = identity.avatars
                root.applyColour()
            } catch (error) { console.error("Omakid identity.json is invalid:", error) }
        }
        onFileChanged: reload()
    }

    FileView {
        path: root.stateDir + "/colour"
        watchChanges: true
        onLoaded: { root.colourId = text().trim() || "blue-light"; root.applyColour() }
        onFileChanged: reload()
    }

    FileView {
        path: root.stateDir + "/avatar"
        watchChanges: true
        onLoaded: root.avatar = text().trim() || "orca"
        onFileChanged: reload()
    }

    Process { id: speaker; command: [] }
    Timer {
        id: launchTimer
        interval: root.reducedMotion ? 0 : 120
        onTriggered: Quickshell.execDetached(["omakid-launch", root.pendingExec])
    }
    Timer {
        id: identityAdvance
        interval: root.reducedMotion ? 0 : 520
        onTriggered: root.mode = "identity-avatar"
    }
    Timer {
        id: identityDone
        interval: root.reducedMotion ? 0 : 520
        onTriggered: root.mode = "home"
    }

    PanelWindow {
        id: window
        visible: root.mode !== "hidden"
        anchors { top: true; right: true; bottom: true; left: true }
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: "transparent"
        WlrLayershell.namespace: "omakid"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.mode === "hidden" ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: root.desktopColour
            Behavior on color {
                enabled: !root.reducedMotion
                ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
            }
        }

        Item {
            id: homeView
            anchors.fill: parent
            visible: root.mode === "home"

            Rectangle {
                anchors { top: parent.top; left: parent.left; margins: 24 }
                width: 88
                height: 88
                radius: 44
                color: "transparent"
                border.width: avatarMouse.containsMouse ? 5 : 0
                border.color: root.foreground
                scale: avatarMouse.containsMouse ? 1.05 : 1.0

                Image {
                    anchors.fill: parent
                    anchors.margins: 8
                    source: root.assets + "/avatars/" + root.avatar + ".png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                MouseArea {
                    id: avatarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.speak("me")
                    onClicked: root.mode = "identity-colour"
                }
            }

            Row {
                anchors { top: parent.top; right: parent.right; margins: 24 }
                spacing: 12

                Repeater {
                    model: ["en", "fr"]
                    Rectangle {
                        width: 76
                        height: 52
                        radius: 10
                        color: "transparent"
                        border.width: root.lang === modelData ? 4 : 0
                        border.color: root.foreground
                        opacity: root.lang === modelData ? 1.0 : 0.58

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: root.assets + "/flags/" + modelData + ".svg"
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setLanguage(modelData)
                        }
                    }
                }
            }

            GridLayout {
                id: activityGrid
                anchors.centerIn: parent
                columns: 2
                rowSpacing: 20
                columnSpacing: 64

                Repeater {
                    model: root.tiles
                    Tile {
                        required property var modelData
                        tileId: modelData.id
                        iconSrc: root.assets + "/icons/" + modelData.icon
                        label: modelData.label[root.lang]
                        foreground: root.foreground
                        reducedMotion: root.reducedMotion
                        onEntered: root.speak(modelData.id)
                        onActivated: root.launch(modelData.exec)
                    }
                }
            }
        }

        Item {
            id: identityView
            anchors.fill: parent
            visible: root.mode === "identity-colour" || root.mode === "identity-avatar"

            GridLayout {
                anchors.centerIn: parent
                columns: 3
                rowSpacing: 28
                columnSpacing: 40
                visible: root.mode === "identity-colour"

                Repeater {
                    model: root.colours
                    Rectangle {
                        required property var modelData
                        width: 190
                        height: 190
                        radius: 32
                        color: modelData.colour
                        border.width: colourMouse.containsMouse ? 7 : 0
                        border.color: modelData.text
                        scale: colourMouse.containsMouse ? 1.04 : 1.0

                        MouseArea {
                            id: colourMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.speak("colour-" + modelData.id)
                            onClicked: root.chooseColour(modelData)
                        }
                    }
                }
            }

            GridLayout {
                anchors.centerIn: parent
                columns: 3
                rowSpacing: 28
                columnSpacing: 40
                visible: root.mode === "identity-avatar"

                Repeater {
                    model: root.avatars
                    Rectangle {
                        required property var modelData
                        width: 190
                        height: 190
                        radius: 32
                        color: "#FFFFFF"
                        border.width: animalMouse.containsMouse ? 7 : 0
                        border.color: root.foreground
                        scale: animalMouse.containsMouse ? 1.04 : 1.0

                        Image {
                            anchors.fill: parent
                            anchors.margins: 18
                            source: root.assets + "/avatars/" + modelData.id + ".png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }

                        MouseArea {
                            id: animalMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.speak("avatar-" + modelData.id)
                            onClicked: root.chooseAvatar(modelData)
                        }
                    }
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 20 }
                width: 88
                height: 64
                radius: 24
                color: "transparent"
                border.width: identityHomeMouse.containsMouse ? 5 : 0
                border.color: root.foreground

                Text {
                    anchors.centerIn: parent
                    text: "⌂"
                    color: root.foreground
                    font.pixelSize: 52
                    font.bold: true
                }

                MouseArea {
                    id: identityHomeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mode = "home"
                }
            }
        }
    }
}
