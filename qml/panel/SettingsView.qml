import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// the settings tab of the atlas. four sections: bar, globe, look, window.
// a setting with `when` only shows while that holds. every one is a SettingRow with
// a hint and a reset arrow once changed. saved at once by SettingsStore and applied
// everywhere through TravelModel
Item {
    id: root

    property var store: null
    property var readSetting: null            // function(key, fallback): the shell's setting()
    property color ink: "white"               // text and soft tints
    property color accent: "#7aa2f7"          // filled / selected parts
    property color panelBg: "black"
    property color barFg: "white"
    property string fontFamily: ""
    property string footnote: ""              // extra line under the sections (theme status)
    property bool popped: false               // the atlas is in its own window right now

    property bool confirmReset: false

    readonly property color inkOnFg: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55
        ? Qt.rgba(0.07, 0.07, 0.09, 1) : Qt.rgba(0.97, 0.97, 0.98, 1)
    readonly property color panelSolid: Qt.rgba(panelBg.r, panelBg.g, panelBg.b, 1)
    function tint(a) { return Qt.rgba(ink.r, ink.g, ink.b, a) }

    // keep this list, manifest.json and BarWidget.qml in sync (tests/test_manifest.py checks)
    readonly property var sections: [
        {
            title: "Bar",
            items: [
                { key: "icon", label: "Bar icon", kind: "string", fallback: "\ud83c\udf0d", maxLength: 8,
                  hint: "Up to 8 characters shown in the bar, for example an emoji." },
                { key: "showCounts", label: "Show counts", kind: "bool", fallback: true,
                  hint: "Countries and cities next to the icon." },
                { key: "clickAction", label: "Left click", kind: "enum", fallback: "panel",
                  options: ["panel", "settings", "none"],
                  labels: { panel: "Open the atlas", settings: "Open settings", none: "Nothing" },
                  hint: "What a left click on the widget does. Right click always opens the settings." },
                { key: "middleAction", label: "Middle click", kind: "enum", fallback: "none",
                  options: ["none", "panel", "settings"],
                  labels: { none: "Nothing", panel: "Open the atlas", settings: "Open settings" },
                  hint: "What a middle click on the widget does." },
                { key: "maxTooltipCountries", label: "Countries in the tooltip", kind: "int", fallback: 8,
                  min: 1, max: 30, step: 1,
                  hint: "How many countries the bar tooltip lists before \"+ N more\"." },
                { key: "maxTooltipCities", label: "Cities per country", kind: "int", fallback: 10,
                  min: 1, max: 30, step: 1,
                  hint: "How many cities the tooltip lists under each country." }
            ]
        },
        {
            title: "Globe",
            items: [
                { key: "showFlags", label: "Show flags", kind: "bool", fallback: true,
                  hint: "Country flag emoji in the lists and the tooltip." },
                { key: "showPath", label: "Travel path on the globe", kind: "bool", fallback: true,
                  hint: "Draw arcs between your dated visits, in order." },
                { key: "showPlaces", label: "City labels on the globe", kind: "bool", fallback: true,
                  hint: "Label cities as you zoom in." }
            ]
        },
        {
            title: "Look",
            items: [
                { key: "theme", label: "Atlas theme", kind: "enum", fallback: "auto",
                  options: ["auto", "custom", "catppuccin", "dracula", "everforest", "gruvbox", "kanagawa", "mono", "nord", "omarchy", "rose-pine", "tokyo-night"],
                  labels: { auto: "Follow Omarchy", custom: "Custom" },
                  hint: "Colors of the atlas and the globe. Follow Omarchy updates the moment you switch your theme. Custom uses the three colors below." },
                { key: "customBg", label: "Background", kind: "color", fallback: "#1a1b26", maxLength: 7,
                  presets: ["#1a1b26", "#1e1e2e", "#1d2021", "#2e3440", "#191724", "#121216", "#0f0f0f", "#f2f2f4"],
                  hint: "Pick one, or type a hex like #1a1b26.",
                  when: [{ key: "theme", is: ["custom"] }] },
                { key: "customFg", label: "Text", kind: "color", fallback: "#c0caf5", maxLength: 7,
                  presets: ["#c0caf5", "#cdd6f4", "#ebdbb2", "#d8dee9", "#e0def4", "#f2f2f4", "#e8dcc8", "#1a1b26"],
                  hint: "Pick one, or type a hex like #c0caf5.",
                  when: [{ key: "theme", is: ["custom"] }] },
                { key: "accentColor", label: "Accent", kind: "color", fallback: "#7aa2f7", maxLength: 7,
                  presets: ["#ff6a1f", "#7aa2f7", "#bb9af7", "#7dcfff", "#9ece6a", "#e0af68", "#f7768e", "#c0caf5"],
                  hint: "Selected parts, pins and the travel path.",
                  when: [{ key: "theme", is: ["custom"] }] },
                { key: "opacity", label: "Opacity", kind: "int", fallback: 100, min: 50, max: 100, step: 1,
                  hint: "Background opacity of the atlas. Text, globe and buttons stay solid." },
                { key: "cornerRadius", label: "Roundness", kind: "int", fallback: 12, min: 0, max: 24, step: 2,
                  hint: "Corners of the docked atlas. 0 is square, 24 is very round." },
                { key: "outline", label: "Window outline", kind: "bool", fallback: false,
                  hint: "Draw the edge of the docked atlas in the accent color instead of a plain neutral line." },
                { key: "surfaceTint", label: "Window tint", kind: "int", fallback: 0, min: 0, max: 30, step: 1,
                  hint: "How much of the accent color washes over the background. 0 keeps it plain." },
                { key: "fontScale", label: "Text size", kind: "int", fallback: 100, min: 80, max: 150, step: 5,
                  divisor: 100, decimals: 2,
                  hint: "1 is normal, 1.25 is a quarter bigger." },
                { key: "density", label: "Spacing", kind: "enum", fallback: "comfortable",
                  options: ["compact", "comfortable", "spacious"],
                  labels: { compact: "Compact", comfortable: "Comfortable", spacious: "Spacious" },
                  hint: "How much air there is around the edges of the atlas." }
            ]
        },
        {
            title: "Window",
            items: [
                { key: "openAs", label: "Open as", kind: "enum", fallback: "panel",
                  options: ["panel", "window"],
                  labels: { panel: "Bar panel", window: "Own window" },
                  hint: "Where the bar icon opens the atlas. You can always pop it out or dock it back from the header." },
                { key: "windowWidth", label: "Width", kind: "int", fallback: 1180, min: 800, max: 1800, step: 20,
                  hint: "How wide the docked atlas opens." },
                { key: "windowHeight", label: "Height", kind: "int", fallback: 760, min: 500, max: 1200, step: 20,
                  hint: "How tall the docked atlas opens. It never grows past the screen." }
            ]
        }
    ]

    readonly property var defaults: {
        var d = ({})
        for (var s = 0; s < sections.length; s++)
            for (var i = 0; i < sections[s].items.length; i++)
                d[sections[s].items[i].key] = sections[s].items[i].fallback
        return d
    }

    // value: panel edit, then the shell's setting, then the default
    function val(key) {
        var fb = root.defaults[key]
        var raw = root.store ? root.store.values[key] : undefined
        if (raw !== undefined) return raw
        if (root.readSetting) {
            var s = root.readSetting(key, fb)
            if (s !== undefined && s !== null) return s
        }
        return fb
    }

    // a setting with `when` only shows while every condition holds
    function shown(item) {
        if (!item.when) return true
        for (var i = 0; i < item.when.length; i++) {
            var c = item.when[i]
            if (c.is.map(String).indexOf(String(root.val(c.key))) < 0) return false
        }
        return true
    }

    // the window manager sizes the pop-out window, so width and height do nothing there.
    // shown but locked until it's docked again
    function offHere(item) {
        return root.popped && (item.key === "windowWidth" || item.key === "windowHeight")
    }

    function setValue(item, v) {
        if (root.offHere(item)) return
        if (item.kind === "color" && !/^#[0-9a-fA-F]{6}$/.test(String(v).trim())) return
        if (root.store) root.store.set(item.key, v)
    }

    function resetAll() {
        if (!root.store) return
        if (!root.confirmReset) {
            root.confirmReset = true
            confirmTimer.restart()
            return
        }
        root.confirmReset = false
        root.store.resetAll(root.defaults)
    }

    Timer { id: confirmTimer; interval: 2500; onTriggered: root.confirmReset = false }

    // clipboard paste for text fields
    // native paste is off in SettingRow. a paste runs a fixed command reading max 1 KB,
    // the text goes back to the row that asked. one at a time, extra requests dropped
    property var pasteRow: null
    property var pasteTarget: null

    function requestPaste(row, target) {
        if (pasteProc.running) return
        pasteRow = row
        pasteTarget = target
        pasteProc.running = true
    }

    function finishPaste(raw) {
        var row = pasteRow
        var target = pasteTarget
        pasteRow = null
        pasteTarget = null
        if (!row || !target) return
        try { row.insertPasted(target, raw) } catch (e) { }
    }

    Process {
        id: pasteProc
        running: false
        command: ["sh", "-c", "timeout 2 wl-paste --no-newline 2>/dev/null | head -c 1024"]
        stdout: StdioCollector {
            id: pasteOut
            onStreamFinished: root.finishPaste(pasteOut.text)
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 28
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            x: 14
            y: 12
            width: flick.width - 28
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        textFormat: Text.PlainText
                        text: "Settings"
                        color: root.ink
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Text {
                        textFormat: Text.PlainText
                        text: "Changes apply instantly"
                        color: root.ink
                        opacity: 0.6
                        font.family: root.fontFamily
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    implicitWidth: resetLabel.implicitWidth + 16
                    implicitHeight: resetLabel.implicitHeight + 10
                    radius: 6
                    color: root.confirmReset ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25) : root.tint(0.08)
                    Text {
                        id: resetLabel
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        text: root.confirmReset ? "Click again to confirm" : "Reset all"
                        color: root.ink
                        font.family: root.fontFamily
                        font.pixelSize: 9
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetAll()
                    }
                }
            }

            Repeater {
                model: root.sections

                delegate: ColumnLayout {
                    id: section
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        textFormat: Text.PlainText
                        text: section.modelData.title.toUpperCase()
                        color: root.ink
                        opacity: 0.55
                        font.family: root.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1.2
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: rows.implicitHeight + 8
                        radius: 10
                        color: root.tint(0.035)
                        border.width: 1
                        border.color: root.tint(0.07)

                        ColumnLayout {
                            id: rows
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            anchors.topMargin: 4
                            spacing: 0

                            Repeater {
                                model: section.modelData.items

                                delegate: ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    visible: root.shown(modelData)

                                    Rectangle {
                                        visible: index > 0
                                        Layout.fillWidth: true
                                        implicitHeight: 1
                                        color: root.tint(0.07)
                                    }

                                    SettingRow {
                                        id: settingRow
                                        Layout.fillWidth: true
                                        Layout.topMargin: 12
                                        Layout.bottomMargin: 12

                                        label: modelData.label
                                        hint: root.offHere(modelData)
                                            ? "Not used in a pop-out window: your window manager sizes it. Dock the atlas to use this."
                                            : (modelData.hint || "")
                                        kind: modelData.kind
                                        options: modelData.options || []
                                        labels: modelData.labels || ({})
                                        presets: modelData.presets || []
                                        maxLength: modelData.maxLength !== undefined ? modelData.maxLength : 256
                                        min: modelData.min !== undefined ? modelData.min : 0
                                        max: modelData.max !== undefined ? modelData.max : 100
                                        step: modelData.step !== undefined ? modelData.step : 1
                                        divisor: modelData.divisor !== undefined ? modelData.divisor : 1
                                        decimals: modelData.decimals !== undefined ? modelData.decimals : 0
                                        defaultValue: modelData.fallback
                                        dimmed: false
                                        locked: root.offHere(modelData)
                                        value: root.val(modelData.key)

                                        fg: root.ink
                                        accent: root.accent
                                        bg: root.inkOnFg
                                        panel: root.panelSolid
                                        barFg: root.barFg
                                        fontFamily: root.fontFamily
                                        schemeAccent: root.accent
                                        schemeBg: root.panelSolid
                                        schemeCustom: root.accent
                                        schemeNeutral: root.panelSolid
                                        schemeMono: root.ink

                                        onEdited: function(v) { root.setValue(modelData, v) }
                                        onClipboardPaste: function(target, maxBytes) { root.requestPaste(settingRow, target) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.footnote !== ""
                textFormat: Text.PlainText
                text: root.footnote
                color: root.ink
                opacity: 0.6
                font.family: root.fontFamily
                font.pixelSize: 9
                wrapMode: Text.Wrap
            }
        }
    }
}
