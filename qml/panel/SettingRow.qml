import QtQuick
import QtQuick.Layouts

// one setting: label + hint left, value / reset right, control below.
// kinds: enum (segments <= 4, else chips), scheme (color tiles), int (slider + -/+ + default notch),
// bool (switch), string (field + preset chips), color (swatches + hex).
// text and soft tints from fg, selected parts in accent. no px / ms / % suffixes on purpose.
// text fields are SafeField, never TextInput (that one keeps reading the clipboard).
// paste goes out as clipboardPaste(target, maxBytes), owner reads max that and calls insertPasted()
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string kind: "string"
    property var options: []
    property var labels: ({})          // option -> friendly text
    property var presets: []           // string chips / color palette
    property var value: null
    property var defaultValue: null
    property real min: 0
    property real max: 100
    property real step: 1
    property real divisor: 1           // shown value = value / divisor
    property int decimals: 0
    property bool dimmed: false        // does nothing right now
    property bool locked: false        // shown, but does nothing right now and ignores input
    property color fg: "white"
    property color accent: fg          // selected / filled parts
    property color bg: "black"         // text on an accent fill
    property color panel: "black"      // solid popup background
    property color barFg: fg           // bar foreground
    property color schemeAccent: "#7aa2f7"   // swatches for the scheme tiles
    property color schemeBg: "#1a1b26"
    property color schemeCustom: "#7aa2f7"
    property color schemeNeutral: "#121216"  // mono / custom background
    property color schemeMono: "#f2f2f4"     // mono ink
    property string fontFamily: ""
    property color customColor: "#7aa2f7"
    property var demoSpectrum: []
    property var demoScope: []

    // byte cap for any clipboard read from a text field
    property int pasteMaxBytes: 1024
    property int maxLength: 256        // text fields: max chars stored

    signal edited(var v)
    signal clipboardPaste(var target, int maxBytes)

    // ---- helpers ----
    function tint(a) { return Qt.rgba(fg.r, fg.g, fg.b, a) }
    function accentTint(a) { return Qt.rgba(accent.r, accent.g, accent.b, a) }
    function str(v) { return (v === null || v === undefined) ? "" : String(v) }
    function same(a, b) { return str(a) === str(b) }
    function labelFor(opt) { return labels[opt] !== undefined ? labels[opt] : String(opt) }
    function show(v) {
        var n = Number(v) / divisor
        if (!isFinite(n)) return "?"
        return String(parseFloat(n.toFixed(decimals)))
    }
    function clamp01(t) { return Math.max(0, Math.min(1, t)) }
    function nudge(dir) {
        var cur = Number(value)
        var v = Math.max(min, Math.min(max, cur + dir * step))
        if (v !== cur) edited(v)
    }

    // ask for a capped clipboard read for target, owner answers with insertPasted()
    function boundedPaste(target) { clipboardPaste(target, pasteMaxBytes) }

    // owner calls this with the capped text. single line, at the cursor
    function insertPasted(target, raw) {
        if (!target) return
        var t = String(raw === null || raw === undefined ? "" : raw).split(/\r?\n/)[0]
        target.insert(target.cursorPosition, t)
    }

    readonly property bool boolValue: value === true || value === "true"
    readonly property bool atDefault: defaultValue === null || same(value, defaultValue)
    readonly property real span: Math.max(1e-9, max - min)
    readonly property real frac: clamp01((Number(value) - min) / span)
    readonly property real defFrac: clamp01((Number(defaultValue) - min) / span)
    readonly property bool useSegments: kind === "enum" && options.length <= 4

    implicitWidth: 400
    implicitHeight: col.implicitHeight
    opacity: (dimmed || locked) ? 0.4 : 1.0
    enabled: !locked
    Behavior on opacity { NumberAnimation { duration: 140 } }

    // small square button (-, +, reset)
    component IconButton: Rectangle {
        id: btn
        property string glyph: ""
        property color ink: "white"
        signal clicked()
        implicitWidth: 22
        implicitHeight: 22
        radius: 6
        color: area.containsMouse
            ? Qt.rgba(ink.r, ink.g, ink.b, 0.18)
            : Qt.rgba(ink.r, ink.g, ink.b, 0.08)
        Text {
            textFormat: Text.PlainText  // plain text only
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.ink
            font.family: root.fontFamily
            font.pixelSize: 11
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // single line editor that is not a TextInput (those hook the clipboard and read it on every
    // change). plain Text + own keys. paste only via ctrl+v / shift+insert -> pasteRequested.
    // no IME, no copy/cut, no mouse selection
    component SafeField: Item {
        id: field
        property string text: ""
        property int maxChars: 256
        property int cursorPosition: 0
        property bool selectAll: false
        property color color: "white"
        property color selectionColor: "#557aa2f7"
        property string fontFamily: ""
        property real fontPixelSize: 10
        property bool dirty: false
        signal pasteRequested()
        signal editingFinished()

        activeFocusOnTab: true
        clip: true

        function clampCursor() {
            cursorPosition = Math.max(0, Math.min(text.length, cursorPosition))
        }

        // insert plain text at pos (replaces everything after select-all)
        function insert(pos, str) {
            var t = String(str === null || str === undefined ? "" : str)
                .replace(/[\u0000-\u001f\u007f]/g, "")
            if (t === "") return
            var base = text
            if (selectAll) { base = ""; pos = 0; selectAll = false }
            var room = maxChars - base.length
            if (room <= 0) return
            t = t.substring(0, room)
            pos = Math.max(0, Math.min(base.length, pos))
            text = base.substring(0, pos) + t + base.substring(pos)
            cursorPosition = pos + t.length
            dirty = true
        }

        function removeBack() {
            if (selectAll) { text = ""; cursorPosition = 0; selectAll = false; dirty = true; return }
            if (cursorPosition <= 0) return
            text = text.substring(0, cursorPosition - 1) + text.substring(cursorPosition)
            cursorPosition -= 1
            dirty = true
        }

        function removeForward() {
            if (selectAll) { removeBack(); return }
            if (cursorPosition >= text.length) return
            text = text.substring(0, cursorPosition) + text.substring(cursorPosition + 1)
            dirty = true
        }

        function finish() {
            selectAll = false
            if (dirty) { dirty = false; editingFinished() }
        }

        onActiveFocusChanged: {
            if (activeFocus) { cursorPosition = text.length; blink.restart() }
            else finish()
        }

        FontMetrics {
            id: fm
            font.family: field.fontFamily
            font.pixelSize: field.fontPixelSize
        }

        Rectangle {          // select-all highlight
            visible: field.selectAll && field.text !== ""
            x: 0
            width: shown.implicitWidth
            height: shown.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            color: field.selectionColor
        }

        Text {
            id: shown
            textFormat: Text.PlainText
            anchors.verticalCenter: parent.verticalCenter
            text: field.text
            color: field.color
            font.family: field.fontFamily
            font.pixelSize: field.fontPixelSize
        }

        Rectangle {          // caret
            id: caret
            visible: field.activeFocus && blink.on
            width: 1
            height: shown.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            x: fm.advanceWidth(field.text.substring(0, field.cursorPosition))
            color: field.color
        }

        Timer {
            id: blink
            property bool on: true
            interval: 530
            repeat: true
            running: field.activeFocus
            onTriggered: on = !on
            onRunningChanged: if (running) on = true
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton      // middle / right click: ignored, nothing pastes
            cursorShape: Qt.IBeamCursor
            onPressed: function(mouse) {
                field.forceActiveFocus()
                field.selectAll = false
                var best = field.text.length
                for (var i = 0; i <= field.text.length; i++) {
                    if (fm.advanceWidth(field.text.substring(0, i)) >= mouse.x) { best = i; break }
                }
                field.cursorPosition = best
                blink.on = true
            }
        }

        Keys.onPressed: function(event) {
            var mods = event.modifiers
            var ctrl = (mods & Qt.ControlModifier) !== 0
            blink.on = true
            if (event.matches(StandardKey.Paste)
                    || (event.key === Qt.Key_Insert && (mods & Qt.ShiftModifier))) {
                event.accepted = true
                field.pasteRequested()
                return
            }
            if (ctrl && event.key === Qt.Key_A) { selectAll = text !== ""; event.accepted = true; return }
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                finish(); event.accepted = true; return
            case Qt.Key_Backspace: removeBack(); event.accepted = true; return
            case Qt.Key_Delete: removeForward(); event.accepted = true; return
            case Qt.Key_Left: selectAll = false; cursorPosition -= 1; clampCursor(); event.accepted = true; return
            case Qt.Key_Right: selectAll = false; cursorPosition += 1; clampCursor(); event.accepted = true; return
            case Qt.Key_Home: selectAll = false; cursorPosition = 0; event.accepted = true; return
            case Qt.Key_End: selectAll = false; cursorPosition = text.length; event.accepted = true; return
            default: break
            }
            // printable chars only, shortcuts (esc, alt+arrows...) go to the popup
            if (!ctrl && !(mods & Qt.AltModifier) && !(mods & Qt.MetaModifier)
                    && event.text.length > 0 && event.text.charCodeAt(0) >= 32
                    && event.text.charCodeAt(0) !== 127) {
                insert(cursorPosition, event.text)
                event.accepted = true
            }
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 9

        // ---- head: label + hint | value / switch / reset ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    textFormat: Text.PlainText  // plain text only
                    Layout.fillWidth: true
                    text: root.label
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    textFormat: Text.PlainText  // plain text only
                    Layout.fillWidth: true
                    text: root.hint
                    visible: root.hint !== ""
                    color: root.fg
                    opacity: 0.55
                    font.family: root.fontFamily
                    font.pixelSize: 8
                    wrapMode: Text.Wrap
                }
            }

            // number stepper
            RowLayout {
                visible: root.kind === "int"
                spacing: 4
                Layout.alignment: Qt.AlignTop

                IconButton { glyph: "\u2212"; ink: root.fg; onClicked: root.nudge(-1) }
                Text {
                    textFormat: Text.PlainText  // plain text only
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignHCenter
                    text: root.show(root.value)
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
                IconButton { glyph: "+"; ink: root.fg; onClicked: root.nudge(1) }
            }

            // switch
            Rectangle {
                visible: root.kind === "bool"
                Layout.alignment: Qt.AlignTop
                implicitWidth: 40
                implicitHeight: 22
                radius: 11
                color: root.boolValue ? root.accent : root.tint(0.14)
                Behavior on color { ColorAnimation { duration: 120 } }

                Rectangle {
                    width: 16; height: 16; radius: 8
                    y: 3
                    x: root.boolValue ? parent.width - width - 3 : 3
                    color: root.boolValue ? root.bg : root.tint(0.75)
                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.edited(!root.boolValue)
                }
            }

            // back to default, only when changed
            IconButton {
                visible: !root.atDefault
                Layout.alignment: Qt.AlignTop
                glyph: "\u21BA"
                ink: root.fg
                onClicked: root.edited(root.defaultValue)
            }
        }

        // ---- enum: segments ----
        Rectangle {
            visible: root.useSegments
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 7
            color: root.tint(0.06)
            border.width: 1
            border.color: root.tint(0.08)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 2

                Repeater {
                    model: root.useSegments ? root.options : []
                    delegate: Rectangle {
                        readonly property bool on: root.same(root.value, modelData)
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        radius: 6
                        color: on ? root.accent : (seg.containsMouse ? root.tint(0.10) : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            textFormat: Text.PlainText  // plain text only
                            anchors.centerIn: parent
                            width: parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.labelFor(modelData)
                            color: parent.on ? root.bg : root.fg
                            font.family: root.fontFamily
                            font.pixelSize: 9
                            font.weight: parent.on ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            id: seg
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.edited(modelData)
                        }
                    }
                }
            }
        }

        // ---- enum with lots of options: chips ----
        Flow {
            visible: root.kind === "enum" && !root.useSegments
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: (root.kind === "enum" && !root.useSegments) ? root.options : []
                delegate: Rectangle {
                    readonly property bool on: root.same(root.value, modelData)
                    implicitWidth: chipText.implicitWidth + 20
                    implicitHeight: 26
                    radius: 6
                    color: on ? root.accent : root.tint(0.07)
                    Text {
                        textFormat: Text.PlainText  // plain text only
                        id: chipText
                        anchors.centerIn: parent
                        text: root.labelFor(modelData)
                        color: parent.on ? root.bg : root.fg
                        font.family: root.fontFamily
                        font.pixelSize: 9
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.edited(modelData)
                    }
                }
            }
        }

        // ---- colors: tiles drawing the real thing ----
        GridLayout {
            visible: root.kind === "scheme"
            Layout.fillWidth: true
            columns: root.kind === "scheme" ? 3 : 4
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: root.kind === "scheme" ? root.options : []
                delegate: Rectangle {
                    id: tile
                    readonly property bool on: root.same(root.value, modelData)
                    readonly property bool isRing: root.kind === "viz" && modelData === "ring"
                    Layout.preferredWidth: Math.floor((root.width - (root.kind === "scheme" ? 16 : 24)) / (root.kind === "scheme" ? 3 : 4))
                    Layout.preferredHeight: root.kind === "scheme" ? 62 : 54
                    radius: 8
                    color: on ? root.accentTint(0.16) : (tileArea.containsMouse ? root.tint(0.10) : root.tint(0.05))
                    border.width: on ? 1.5 : 1
                    border.color: on ? root.accent : root.tint(0.10)
                    Behavior on color { ColorAnimation { duration: 100 } }

                    // scheme tile, a tiny panel in that scheme
                    Rectangle {
                        visible: root.kind === "scheme"
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 8
                        width: parent.width - 20
                        height: 30
                        radius: 5
                        color: modelData === "theme" ? root.schemeBg
                             : root.schemeNeutral
                        border.width: 1
                        border.color: root.tint(0.14)
                        readonly property color swatch: modelData === "theme" ? root.schemeAccent
                            : (modelData === "custom" ? root.schemeCustom
                               : root.schemeMono)

                        Rectangle {   // fake selected segment
                            x: 6; y: 6; width: 16; height: 7; radius: 3
                            color: parent.swatch
                        }
                        Rectangle {   // fake slider
                            x: 6; y: 18; width: parent.width - 12; height: 4; radius: 2
                            color: Qt.rgba(root.schemeMono.r, root.schemeMono.g, root.schemeMono.b, 0.18)
                            Rectangle {
                                width: parent.width * 0.55; height: parent.height; radius: 2
                                color: parent.parent.swatch
                            }
                        }
                    }
                    Text {
                        textFormat: Text.PlainText  // plain text only
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 7
                        text: root.labelFor(modelData)
                        color: root.fg
                        opacity: tile.on ? 1.0 : 0.7
                        font.family: root.fontFamily
                        font.pixelSize: 8
                        font.weight: tile.on ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        id: tileArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.edited(modelData)
                    }
                }
            }
        }

        // ---- int: slider ----
        ColumnLayout {
            visible: root.kind === "int"
            Layout.fillWidth: true
            spacing: 1

            Item {
                id: slider
                Layout.fillWidth: true
                implicitHeight: 22
                readonly property real knob: 16

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: root.tint(0.12)

                    Rectangle {
                        width: handle.x + handle.width / 2
                        height: parent.height
                        radius: parent.radius
                        color: root.accent
                    }
                }
                // notch where the default is
                Rectangle {
                    visible: root.defaultValue !== null
                    width: 2; height: 12; radius: 1
                    x: (slider.width - slider.knob) * root.defFrac + slider.knob / 2 - 1
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.tint(0.35)
                }
                Rectangle {
                    id: handle
                    width: slider.knob; height: slider.knob; radius: slider.knob / 2
                    x: (slider.width - width) * root.frac
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.accent
                    border.width: 3
                    border.color: root.panel
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function apply(mx) {
                        var room = Math.max(1, slider.width - slider.knob)
                        var t = Math.max(0, Math.min(1, (mx - slider.knob / 2) / room))
                        var v = root.min + t * (root.max - root.min)
                        v = Math.round((v - root.min) / root.step) * root.step + root.min
                        v = Math.max(root.min, Math.min(root.max, v))
                        // only real changes, so a drag doesn't rewrite the config every pixel
                        if (v !== Number(root.value)) root.edited(v)
                    }
                    onPressed: function(m) { apply(m.x) }
                    onPositionChanged: function(m) { if (pressed) apply(m.x) }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    textFormat: Text.PlainText  // plain text only
                    text: root.show(root.min)
                    color: root.fg; opacity: 0.4
                    font.family: root.fontFamily; font.pixelSize: 8
                }
                Item { Layout.fillWidth: true }
                Text {
                    textFormat: Text.PlainText  // plain text only
                    text: root.show(root.max)
                    color: root.fg; opacity: 0.4
                    font.family: root.fontFamily; font.pixelSize: 8
                }
            }
        }

        // ---- string: field + preset chips ----
        RowLayout {
            visible: root.kind === "string"
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: root.presets.length > 0 ? 90 : 200
                Layout.fillWidth: root.presets.length === 0
                implicitHeight: 26
                radius: 6
                color: root.tint(0.06)
                border.width: 1
                border.color: textIn.activeFocus ? root.accent : root.tint(0.12)

                SafeField {
                    id: textIn

                    maxChars: root.maxLength

                    onPasteRequested: root.boundedPaste(textIn)
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    color: root.fg
                    selectionColor: root.accentTint(0.35)
                    fontFamily: root.fontFamily
                    fontPixelSize: 10
                    onEditingFinished: root.edited(text)
                    // follow the store unless you're typing
                    Binding on text {
                        when: !textIn.activeFocus
                        value: root.str(root.value)
                    }
                }
            }

            Flow {
                visible: root.presets.length > 0
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.kind === "string" ? root.presets : []
                    delegate: Rectangle {
                        readonly property bool on: root.same(root.value, modelData)
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 6
                        color: on ? root.accent : (pArea.containsMouse ? root.tint(0.14) : root.tint(0.07))
                        Text {
                            textFormat: Text.PlainText  // plain text only
                            anchors.centerIn: parent
                            text: String(modelData).trim() === "" ? "\u2423" : String(modelData).trim()
                            color: parent.on ? root.bg : root.fg
                            font.family: root.fontFamily
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: pArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.edited(modelData)
                        }
                    }
                }
            }
        }

        // ---- color: swatches + hex ----
        ColumnLayout {
            visible: root.kind === "color"
            Layout.fillWidth: true
            spacing: 8

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.kind === "color" ? root.presets : []
                    delegate: Rectangle {
                        readonly property bool on: root.str(root.value).toLowerCase() === String(modelData).toLowerCase()
                        width: 24; height: 24; radius: 12
                        color: modelData
                        border.width: on ? 2 : 1
                        border.color: on ? root.fg : root.tint(0.2)
                        scale: cArea.containsMouse ? 1.12 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        MouseArea {
                            id: cArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.edited(modelData)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    readonly property bool valid: /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(root.str(root.value))
                    width: 28; height: 28; radius: 6
                    color: valid ? root.str(root.value) : "transparent"
                    border.width: 1
                    border.color: root.tint(0.25)
                }
                Rectangle {
                    Layout.preferredWidth: 110
                    implicitHeight: 28
                    radius: 6
                    color: root.tint(0.06)
                    border.width: 1
                    border.color: hexIn.activeFocus ? root.accent : root.tint(0.12)

                    SafeField {
                        id: hexIn

                        maxChars: 9          // '#' + 8 hex digits

                        onPasteRequested: root.boundedPaste(hexIn)
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        color: root.fg
                        selectionColor: root.accentTint(0.35)
                        fontFamily: root.fontFamily
                        fontPixelSize: 10
                        onEditingFinished: root.edited(text)
                        Binding on text {
                            when: !hexIn.activeFocus
                            value: root.str(root.value)
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
