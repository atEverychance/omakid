// Omakid "Me" picker: two screens, six choices each, no text required.
// Instant feedback — tap green and the screen IS green before the finger lifts.
// No confirm button. No Apply. No OK. Nothing gates the desktop.
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    property string lang: "en"
    property var colours: []
    property var avatars: []
    property string pickedColour: ""
    property string pickedAvatar: ""
    property int screen: 0          // 0 = colour, 1 = avatar

    readonly property string assets: Quickshell.env("OMAKID_ASSETS")
                                     || "/usr/share/omakid/assets"

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/omakid/lang"
        watchChanges: true
        onLoaded: root.lang = (text().trim() || "en")
        onFileChanged: reload()
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/omakid/identity.json"
        watchChanges: true
        onLoaded: {
            try {
                const j = JSON.parse(text())
                root.colours = j.colours
                root.avatars = j.avatars
            } catch (e) { console.warn("identity.json invalid:", e) }
        }
        onFileChanged: reload()
    }

    Process { id: speaker; command: [] }
    function speak(clip) {
        speaker.running = false
        speaker.command = ["paplay", `${root.assets}/voice/${root.lang}/${clip}.wav`]
        speaker.running = true
    }

    function apply(kind, id) {
        Quickshell.execDetached(["omakid-set-identity", kind, id])
    }

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        focusable: true

        // live preview: the background IS the choice
        Rectangle {
            id: bg
            anchors.fill: parent
            color: root.pickedColour || "#0f4c4c"
            Behavior on color { ColorAnimation { duration: 220 } }
        }

        // --- screen 0: colour ----------------------------------------
        GridLayout {
            visible: root.screen === 0
            anchors.centerIn: parent
            columns: 3
            rowSpacing: 48
            columnSpacing: 48

            Repeater {
                model: root.colours
                Rectangle {
                    width: 220; height: 220; radius: 36
                    color: modelData.swatch
                    border.width: sa.containsMouse ? 8 : 0
                    border.color: "#ffffff"
                    scale: sa.containsMouse ? 1.07 : 1.0
                    Behavior on scale { NumberAnimation { duration: 140 } }

                    MouseArea {
                        id: sa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.speak("colour-" + modelData.id)
                        onClicked: {
                            root.pickedColour = modelData.swatch
                            root.apply("colour", modelData.id)
                            nextScreen.start()
                        }
                    }
                }
            }
        }

        // --- screen 1: avatar ----------------------------------------
        GridLayout {
            visible: root.screen === 1
            anchors.centerIn: parent
            columns: 3
            rowSpacing: 48
            columnSpacing: 48

            Repeater {
                model: root.avatars
                Rectangle {
                    width: 220; height: 220; radius: 36
                    color: "#ffffff"
                    opacity: 0.92
                    border.width: aa.containsMouse ? 8 : 0
                    border.color: "#ffffff"
                    scale: aa.containsMouse ? 1.07 : 1.0
                    Behavior on scale { NumberAnimation { duration: 140 } }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 24
                        source: `${root.assets}/avatars/${modelData.id}.png`
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }

                    MouseArea {
                        id: aa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.speak("avatar-" + modelData.id)
                        onClicked: {
                            root.pickedAvatar = modelData.id
                            root.apply("avatar", modelData.id)
                            done.start()
                        }
                    }
                }
            }
        }

        // advance after the colour lands, so she sees it happen
        Timer { id: nextScreen; interval: 700; onTriggered: root.screen = 1 }
        Timer { id: done;       interval: 700; onTriggered: Qt.quit() }

        // escape hatch: tap-through or walk away, defaults still apply
        MouseArea {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter
                      bottomMargin: 40 }
            width: 120; height: 120
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.quit()
            Image {
                anchors.fill: parent
                source: `${root.assets}/icons/home.png`
                fillMode: Image.PreserveAspectFit
                opacity: 0.55
            }
        }
    }
}
