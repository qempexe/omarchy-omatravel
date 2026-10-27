import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// the About tab: the logo, the name and version, who made it, and where to find more
// plugins by the same author
Item {
    id: root

    property color ink: "white"
    property color accent: "#7aa2f7"
    property string fontFamily: ""
    property bool lightPanel: false           // the light logo on a dark panel, the dark one on a light panel

    // the author's plugins, in one place. a fixed address, opened with xdg-open
    readonly property string moreUrl: "https://github.com/qempexe?tab=repositories&q=omarchy"
    property string version: ""

    // the version, read from the plugin's own manifest
    FileView {
        path: decodeURIComponent(Qt.resolvedUrl("../../manifest.json").toString().replace(/^file:\/\//, ""))
        onLoaded: {
            var v = ""
            try { v = String(JSON.parse(text()).version || "") } catch (e) { v = "" }
            root.version = /^[0-9A-Za-z.+-]{1,32}$/.test(v) ? v : ""
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -16
        spacing: 6

        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            source: Qt.resolvedUrl(root.lightPanel ? "../../assets/logo-dark.png" : "../../assets/logo.png")
            sourceSize.width: 192
            sourceSize.height: 192
            smooth: true
            mipmap: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            textFormat: Text.PlainText
            text: "OMATRAVEL"
            color: root.ink
            font.family: root.fontFamily
            font.pixelSize: 19
            font.weight: Font.DemiBold
            font.letterSpacing: 4
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.version !== ""
            textFormat: Text.PlainText
            text: "Version " + root.version
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            Text {
                textFormat: Text.PlainText
                text: "made with "
                color: root.ink
                opacity: 0.75
                font.family: root.fontFamily
                font.pixelSize: 12
            }
            Text {   // the system font: the panel's font draws the heart as an outline
                textFormat: Text.PlainText
                text: "♥"
                color: root.accent
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                textFormat: Text.PlainText
                text: " by qempexe"
                color: root.ink
                opacity: 0.75
                font.family: root.fontFamily
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            implicitWidth: moreText.implicitWidth + 28
            implicitHeight: 30
            radius: 8
            color: moreArea.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                                          : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.07)
            border.width: 1
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, moreArea.containsMouse ? 0.8 : 0.35)
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                id: moreText
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: "Check out my other plugins ↗"
                color: root.ink
                font.family: root.fontFamily
                font.pixelSize: 11
            }
            MouseArea {
                id: moreArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["xdg-open", root.moreUrl])
            }
        }
    }
}
