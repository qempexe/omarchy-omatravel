import QtQuick
import Quickshell.Io

// small themed text field, no QtQuick.Controls.
// not a TextInput on purpose: those hook the clipboard and keep reading it in the background,
// and this panel stays loaded while hidden. so: plain Text + own key handling.
// paste only on ctrl+v / shift+insert, max pasteMaxBytes, 2s timeout.
// no IME, no copy/cut, no mouse selection
Rectangle {
    id: box

    property string text: ""
    property string placeholderText: ""
    property color foreground: "#e8dcc8"
    property color accent: "#d4a35a"
    property string fontFamily: ""
    property int pixelSize: 12
    property int maxLength: 256
    property int pasteMaxBytes: 1024
    property int cursorPosition: 0
    property bool selectAll: false
    readonly property bool focused: field.activeFocus

    signal accepted()

    function forceFocus() { field.forceActiveFocus() }
    function clear() { text = ""; cursorPosition = 0; selectAll = false }

    // insert single-line text at pos (replaces everything after select-all)
    function insert(pos, str) {
        var t = String(str === null || str === undefined ? "" : str)
            .split(/\r?\n/)[0]
            .replace(/[\u0000-\u001f\u007f]/g, "")
        if (t === "") return
        var base = text
        if (selectAll) { base = ""; pos = 0; selectAll = false }
        var room = maxLength - base.length
        if (room <= 0) return
        t = t.substring(0, room)
        pos = Math.max(0, Math.min(base.length, pos))
        text = base.substring(0, pos) + t + base.substring(pos)
        cursorPosition = pos + t.length
    }

    function removeBack() {
        if (selectAll) { clear(); return }
        if (cursorPosition <= 0) return
        text = text.substring(0, cursorPosition - 1) + text.substring(cursorPosition)
        cursorPosition -= 1
    }

    function removeForward() {
        if (selectAll) { clear(); return }
        if (cursorPosition >= text.length) return
        text = text.substring(0, cursorPosition) + text.substring(cursorPosition + 1)
    }

    function clampCursor() {
        cursorPosition = Math.max(0, Math.min(text.length, cursorPosition))
    }

    // text set from outside (a suggestion chip) keeps the caret in range
    onTextChanged: clampCursor()

    implicitHeight: 34
    radius: 8
    color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.08)
    border.width: 1
    border.color: focused ? accent : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)

    // bounded paste, explicit only, one at a time
    Process {
        id: pasteProc
        running: false
        command: ["sh", "-c", "timeout 2 wl-paste --no-newline 2>/dev/null | head -c \"$1\"",
            "sh", String(Math.max(0, box.pasteMaxBytes))]
        stdout: StdioCollector {
            id: pasteOut
            onStreamFinished: if (field.activeFocus) box.insert(box.cursorPosition, pasteOut.text)
        }
    }

    FontMetrics {
        id: fm
        font.family: box.fontFamily
        font.pixelSize: box.pixelSize
    }

    Item {
        id: field
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        activeFocusOnTab: true
        clip: true

        // keep the caret visible on long text
        readonly property real caretX: fm.advanceWidth(box.text.substring(0, box.cursorPosition))
        readonly property real shift: Math.max(0, caretX - width + 2)

        onActiveFocusChanged: {
            if (activeFocus) { box.cursorPosition = box.text.length; blink.restart() }
            else box.selectAll = false
        }

        Rectangle {          // select-all highlight
            visible: box.selectAll && box.text !== ""
            x: -field.shift
            width: shown.implicitWidth
            height: shown.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            color: box.accent
            opacity: 0.45
        }

        Text {
            id: shown
            x: -field.shift
            anchors.verticalCenter: parent.verticalCenter
            text: box.text
            color: box.foreground
            font.family: box.fontFamily
            font.pixelSize: box.pixelSize
            textFormat: Text.PlainText
        }

        Rectangle {          // caret
            visible: field.activeFocus && blink.on
            width: 1
            height: shown.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            x: field.caretX - field.shift
            color: box.foreground
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
                box.selectAll = false
                var px = mouse.x + field.shift
                var best = box.text.length
                for (var i = 0; i <= box.text.length; i++) {
                    if (fm.advanceWidth(box.text.substring(0, i)) >= px) { best = i; break }
                }
                box.cursorPosition = best
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
                if (!pasteProc.running) pasteProc.running = true
                return
            }
            if (ctrl && event.key === Qt.Key_A) { box.selectAll = box.text !== ""; event.accepted = true; return }
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                box.selectAll = false; box.accepted(); event.accepted = true; return
            case Qt.Key_Backspace: box.removeBack(); event.accepted = true; return
            case Qt.Key_Delete: box.removeForward(); event.accepted = true; return
            case Qt.Key_Left: box.selectAll = false; box.cursorPosition -= 1; box.clampCursor(); event.accepted = true; return
            case Qt.Key_Right: box.selectAll = false; box.cursorPosition += 1; box.clampCursor(); event.accepted = true; return
            case Qt.Key_Home: box.selectAll = false; box.cursorPosition = 0; event.accepted = true; return
            case Qt.Key_End: box.selectAll = false; box.cursorPosition = box.text.length; event.accepted = true; return
            default: break
            }
            // printable chars only, shortcuts (esc, alt+arrows...) go to the panel
            if (!ctrl && !(mods & Qt.AltModifier) && !(mods & Qt.MetaModifier)
                    && event.text.length > 0 && event.text.charCodeAt(0) >= 32
                    && event.text.charCodeAt(0) !== 127) {
                box.insert(box.cursorPosition, event.text)
                event.accepted = true
            }
        }
    }

    Text {
        anchors.fill: field
        verticalAlignment: Text.AlignVCenter
        visible: box.text.length === 0 && !field.activeFocus
        text: box.placeholderText
        color: Qt.rgba(box.foreground.r, box.foreground.g, box.foreground.b, 0.45)
        font.pixelSize: box.pixelSize
        font.family: box.fontFamily
        elide: Text.ElideRight
        textFormat: Text.PlainText
    }
}
