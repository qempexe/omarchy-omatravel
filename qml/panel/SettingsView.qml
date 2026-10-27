import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../js/Schema.js" as Schema

// the settings tab of the atlas:
//   * one underlined tab per group in js/Schema.js, and About last;
//   * that group's settings, in their sections, or every match while the header's
//     search box has text in it;
//   * "Changed only" narrows it to what differs from the defaults, "Reset all" puts
//     everything back.
// a row whose `when` doesn't hold is dimmed, not hidden, so nothing jumps around.
// every change is saved at once by SettingsStore and applied everywhere through TravelModel
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
    property string filter: ""                // what is typed in the header's search box
    property int fsMain: 11
    property int fsSub: 9

    property int group: 0
    property bool changedOnly: false
    property bool confirmReset: false

    readonly property bool searching: filter.trim() !== ""
    readonly property bool onAbout: group === Schema.groups.length && !searching && !changedOnly

    readonly property color inkOnFg: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55
        ? Qt.rgba(0.07, 0.07, 0.09, 1) : Qt.rgba(0.97, 0.97, 0.98, 1)
    readonly property color panelSolid: Qt.rgba(panelBg.r, panelBg.g, panelBg.b, 1)
    readonly property bool lightPanel: (0.299 * panelBg.r + 0.587 * panelBg.g + 0.114 * panelBg.b) > 0.55
    function tint(a) { return Qt.rgba(ink.r, ink.g, ink.b, a) }
    function accentTint(a) { return Qt.rgba(accent.r, accent.g, accent.b, a) }

    // value: panel edit, then the shell's setting, then the default
    function val(key) {
        var fb = Schema.defaults[key]
        var raw = root.store ? root.store.values[key] : undefined
        if (raw !== undefined) return Schema.clean(key, raw)
        if (root.readSetting) {
            var s = root.readSetting(key, fb)
            if (s !== undefined && s !== null) return Schema.clean(key, s)
        }
        return fb
    }
    function same(item) { return String(val(item.key)) === String(item.fallback) }
    function dimmed(item) { return !Schema.active(item, root.val) }

    // the window manager sizes the pop-out window, so width and height do nothing there.
    // shown but locked until it's docked again
    function offHere(item) {
        return root.popped && (item.key === "windowWidth" || item.key === "windowHeight")
    }

    function setValue(item, v) {
        if (root.offHere(item)) return
        if (item.kind === "color" && !/^#[0-9a-fA-F]{6}$/.test(String(v).trim())) return
        if (root.store) root.store.set(item.key, Schema.clean(item.key, v))
    }

    // the rows to show: the chosen group, or every match while searching or showing only
    // what changed. `head` is the heading over a row: the group's title in a list across
    // groups, otherwise the row's section where a new one starts
    readonly property var rows: {
        var across = root.searching || root.changedOnly
        // only "Changed only" reads the values here: anything else would rebuild the rows,
        // and the row being dragged with them, on every change
        var out = []
        for (var g = 0; g < Schema.groups.length; g++) {
            if (!across && g !== root.group) continue
            var items = Schema.groups[g].items
            var first = true, lastSection = ""
            for (var i = 0; i < items.length; i++) {
                var it = items[i]
                if (!Schema.matches(it, root.filter)) continue
                if (root.changedOnly && root.same(it)) continue
                var section = it.section || ""
                var head = across ? (first ? Schema.groups[g].title : "") : (section !== lastSection ? section : "")
                out.push({ item: it, head: head, first: first })
                lastSection = section
                first = false
            }
        }
        return out
    }

    // how many settings differ from their defaults
    readonly property int changed: {
        var tick = root.store ? root.store.values : null
        var n = 0
        for (var i = 0; i < Schema.items.length; i++) if (!root.same(Schema.items[i])) n++
        return n
    }

    function resetAll() {
        if (!root.store) return
        if (!root.confirmReset) {
            root.confirmReset = true
            confirmTimer.restart()
            return
        }
        root.confirmReset = false
        root.store.resetAll(Schema.defaults)
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

    // a small rounded button: "Changed only", "Reset all"
    component Pill: Rectangle {
        id: pill
        property string text: ""
        property bool on: false
        signal clicked()
        implicitWidth: pillText.implicitWidth + 16
        implicitHeight: pillText.implicitHeight + 10
        radius: height / 2
        color: on ? root.accentTint(0.25) : (pillArea.containsMouse ? root.tint(0.12) : root.tint(0.07))
        border.width: 1
        border.color: on ? root.accentTint(0.7) : root.tint(0.10)
        Text {
            id: pillText
            textFormat: Text.PlainText
            anchors.centerIn: parent
            text: pill.text
            color: root.ink
            font.family: root.fontFamily
            font.pixelSize: root.fsSub
        }
        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        spacing: 10

        // ---- tabs -------------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            implicitHeight: 30

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: root.tint(0.10)
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: Schema.groups.concat([{ key: "about", title: "About" }])
                    delegate: Item {
                        id: tabItem
                        required property var modelData
                        required property int index
                        readonly property bool on: index === root.group && !root.searching && !root.changedOnly
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true

                        Text {
                            textFormat: Text.PlainText
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -1
                            text: tabItem.modelData.title
                            color: root.ink
                            opacity: (root.searching || root.changedOnly) ? 0.3
                                     : (tabItem.on ? 1.0 : (tabArea.containsMouse ? 0.8 : 0.5))
                            font.family: root.fontFamily
                            font.pixelSize: root.fsSub + 1
                            font.weight: tabItem.on ? Font.DemiBold : Font.Normal
                        }
                        Rectangle {
                            visible: tabItem.on
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            radius: 1
                            color: root.accent
                        }
                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.group = tabItem.index; root.changedOnly = false }
                        }
                    }
                }
            }
        }

        // ---- the About tab ------------------------------------------------------------
        AboutPage {
            visible: root.onAbout
            Layout.fillWidth: true
            Layout.fillHeight: true
            ink: root.ink
            accent: root.accent
            fontFamily: root.fontFamily
            lightPanel: root.lightPanel
        }

        // ---- what is shown: tools, then the rows ----------------------------------------
        RowLayout {
            visible: !root.onAbout
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            spacing: 8

            Text {
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: root.searching
                      ? (root.rows.length === 0 ? "No setting matches “" + root.filter.trim() + "”"
                                                : root.rows.length + (root.rows.length === 1 ? " setting matches" : " settings match"))
                      : (root.changed === 0 ? "Everything is at its default"
                                            : root.changed + (root.changed === 1 ? " setting changed" : " settings changed"))
                color: root.ink
                opacity: 0.6
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: root.fsSub
            }
            Pill {
                text: "Changed only"
                on: root.changedOnly
                visible: root.changed > 0 || root.changedOnly
                onClicked: root.changedOnly = !root.changedOnly
            }
            Pill {
                text: root.confirmReset ? "Click again to confirm" : "Reset all"
                on: root.confirmReset
                visible: root.changed > 0
                onClicked: root.resetAll()
            }
        }

        Flickable {
            id: flick
            visible: !root.onAbout
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: col.implicitHeight + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                x: 14
                width: flick.width - 28
                spacing: 0

                Repeater {
                    model: root.rows

                    delegate: ColumnLayout {
                        id: rowItem
                        required property var modelData
                        required property int index
                        readonly property var item: modelData.item
                        Layout.fillWidth: true
                        spacing: 0

                        // a section or group heading over the row
                        Text {
                            visible: rowItem.modelData.head !== ""
                            Layout.topMargin: rowItem.index === 0 ? 4 : 18
                            Layout.bottomMargin: 2
                            textFormat: Text.PlainText
                            text: rowItem.modelData.head.toUpperCase()
                            color: root.ink
                            opacity: 0.55
                            font.family: root.fontFamily
                            font.pixelSize: root.fsSub
                            font.letterSpacing: 1.2
                        }

                        Rectangle {
                            visible: rowItem.modelData.head === "" && rowItem.index > 0
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: root.tint(0.07)
                        }

                        SettingRow {
                            id: settingRow
                            Layout.fillWidth: true
                            Layout.topMargin: 12
                            Layout.bottomMargin: 12

                            label: rowItem.item.label
                            hint: root.offHere(rowItem.item)
                                ? "Not used in a pop-out window: your window manager sizes it. Dock the atlas to use this."
                                : (rowItem.item.hint || "")
                            kind: rowItem.item.kind
                            options: rowItem.item.options || []
                            labels: rowItem.item.labels || ({})
                            presets: rowItem.item.presets || []
                            maxLength: rowItem.item.maxLength !== undefined ? rowItem.item.maxLength : 256
                            min: rowItem.item.min !== undefined ? rowItem.item.min : 0
                            max: rowItem.item.max !== undefined ? rowItem.item.max : 100
                            step: rowItem.item.step !== undefined ? rowItem.item.step : 1
                            divisor: rowItem.item.divisor !== undefined ? rowItem.item.divisor : 1
                            decimals: rowItem.item.decimals !== undefined ? rowItem.item.decimals : 0
                            defaultValue: rowItem.item.fallback
                            dimmed: root.dimmed(rowItem.item)
                            locked: root.offHere(rowItem.item)
                            value: root.store ? (root.store.values, root.val(rowItem.item.key)) : rowItem.item.fallback

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

                            onEdited: function(v) { root.setValue(rowItem.item, v) }
                            onClipboardPaste: function(target, maxBytes) { root.requestPaste(settingRow, target) }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    visible: root.footnote !== "" && !root.searching && !root.changedOnly
                             && Schema.groups[root.group] !== undefined && Schema.groups[root.group].key === "look"
                    textFormat: Text.PlainText
                    text: root.footnote
                    color: root.ink
                    opacity: 0.6
                    font.family: root.fontFamily
                    font.pixelSize: root.fsSub
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
