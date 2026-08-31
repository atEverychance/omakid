import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    property string lang: "en"
    property var tiles: []
    property var colours: []
    property string colourId: "blue-light"
    property string desktopColour: "#A8D8F0"
    property string foreground: "#1F1B24"
    readonly property string assets: Quickshell.env("OMAKID_ASSETS")
                                     || "/usr/share/omakid/assets"

    // --- state: which language ---------------------------------------
    FileView {
        id: langFile
        path: Quickshell.env("HOME") + "/.local/state/omakid/lang"
        watchChanges: true
        onLoaded: root.lang = (text().trim() || "en")
        onFileChanged: reload()
    }

    // --- tile definitions --------------------------------------------
    FileView {
        id: tileFile
        path: Quickshell.env("HOME") + "/.config/omakid/tiles.json"
        watchChanges: true
        onLoaded: {
            try { root.tiles = JSON.parse(text()).tiles }
            catch (e) { console.warn("tiles.json invalid:", e) }
        }
        onFileChanged: reload()
    }

    // --- her chosen flat colour ---------------------------------------
    FileView {
        path: Quickshell.env("HOME") + "/.config/omakid/identity.json"
        watchChanges: true
        onLoaded: {
            try {
                root.colours = JSON.parse(text()).colours
                root.applyColour()
            } catch (e) { console.warn("identity.json invalid:", e) }
        }
        onFileChanged: reload()
    }
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/omakid/colour"
        watchChanges: true
        onLoaded: { root.colourId = (text().trim() || "blue-light"); root.applyColour() }
        onFileChanged: reload()
    }
    function applyColour() {
        for (let c of root.colours) {
            if (c.id === root.colourId) {
                root.desktopColour = c.colour
                root.foreground = c.text
                return
            }
        }
    }

    // --- her chosen animal -------------------------------------------
    property string avatar: "orca"
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/omakid/avatar"
        watchChanges: true
        onLoaded: root.avatar = (text().trim() || "orca")
        onFileChanged: reload()
    }

    // --- audio label: pre-recorded wav, not synthesized --------------
    Process { id: speaker; command: [] }

    function speak(id) {
        speaker.running = false
        speaker.command = ["paplay", `${root.assets}/voice/${root.lang}/${id}.wav`]
        speaker.running = true
    }

    function launch(exec) {
        Quickshell.execDetached(["omakid-launch", exec])
    }

    function setLang(l) {
        Quickshell.execDetached(["sh", "-c",
            `mkdir -p ~/.local/state/omakid && echo ${l} > ~/.local/state/omakid/lang`])
    }

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: root.desktopColour

        Rectangle {
            anchors.fill: parent
            color: root.desktopColour
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        // --- her avatar, top left: tap the animal to change it
        Rectangle {
            anchors { top: parent.top; left: parent.left; margins: 32 }
            width: 88; height: 88; radius: 44
            color: root.foreground
            opacity: av.containsMouse ? 1.0 : 0.75
            scale: av.containsMouse ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: 140 } }

            Image {
                anchors.fill: parent
                anchors.margins: 10
                source: `${root.assets}/avatars/${root.avatar}.png`
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            MouseArea {
                id: av
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.speak("me")
                onClicked: Quickshell.execDetached(["omakid-me"])
            }
        }

        // --- language flags, top right -------------------------------
        RowLayout {
            anchors { top: parent.top; right: parent.right; margins: 32 }
            spacing: 12
            Repeater {
                model: ["en", "fr"]
                Rectangle {
                    width: 76; height: 52; radius: 10
                    color: "transparent"
                    border.width: root.lang === modelData ? 3 : 0
                    border.color: root.foreground
                    opacity: root.lang === modelData ? 1.0 : 0.45
                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: `${root.assets}/flags/${modelData}.png`
                        fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setLang(modelData)
                    }
                }
            }
        }

        // --- the grid ------------------------------------------------
        RowLayout {
            anchors.centerIn: parent
            spacing: 64
            Repeater {
                model: root.tiles
                Tile {
                    tileId:  modelData.id
                    iconSrc: `${root.assets}/icons/${modelData.icon}`
                    label:   modelData.label[root.lang]
                    foreground: root.foreground
                    onEntered:   root.speak(modelData.id)
                    onActivated: root.launch(modelData.exec)
                }
            }
        }
    }
}
