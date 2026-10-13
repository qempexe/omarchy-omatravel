import QtQuick
import Quickshell
import qs.Commons

// The window the atlas panel lives in when it is docked to the bar: a bar popup with its own
// thin border and rounded corners, placed flush against the bar's outer edge so it never
// covers the bar, and closed by Esc, the X button or a click outside it.
//
// Children are placed inside the frame (default property), so Panel.qml can put its content
// here and move it to a separate window and back.
PopupWindow {
    id: root

    property bool open: false                 // follows Panel.opened
    property var anchorItem: null
    property bool vertical: false             // bar is on the left / right edge
    property real wantedWidth: 1180
    property real wantedHeight: 760
    property color borderColor: "#33ffffff"
    property real frameRadius: 12
    property var focusTarget: null            // item that should get the keyboard when shown
    signal closeRequested()

    default property alias content: holder.data

    readonly property real contentWidth: Math.max(480, Math.min(wantedWidth, screenW - 40))
    readonly property real contentHeight: Math.min(wantedHeight, maxHeight)

    // ---- placement: never overlap the bar -----------------------------------------
    // Worked out each time the panel is about to open (see onOpenChanged), because the
    // bar's position is not known yet when this file is first loaded.
    //
    // The panel is anchored to the outer edge of the bar's own window (not to the
    // widget, which sits inside the bar's padding), and the gap is transparent
    // padding inside the popup window, so it works whatever the compositor does
    // with anchor margins.
    property var barObject: null              // the shell's bar, used as a hint for its edge
    property bool barAtTop: true              // horizontal bar: top edge (else bottom)
    property bool barAtLeft: true             // vertical bar: left edge (else right)
    property bool useRect: false              // anchor to the bar window's edge
    property var anchorWin: null
    property real rectX: 0
    property real rectY: 0
    property real rectW: 1
    property real rectH: 1
    property real extra: 0                    // extra clearance when only the widget is known
    property real screenW: 1920
    property real maxHeight: 620
    readonly property int gap: 0              // free space between the bar and the panel (0 = flush)
    readonly property real padTop: (!vertical && barAtTop) ? gap + extra : 0
    readonly property real padBottom: (!vertical && !barAtTop) ? gap + extra : 0
    readonly property real padLeft: (vertical && barAtLeft) ? gap + extra : 0
    readonly property real padRight: (vertical && !barAtLeft) ? gap + extra : 0

    function sideFromText(v) {
        var t = String(v === undefined || v === null ? "" : v).toLowerCase()
        if (t.indexOf("top") >= 0) return "top"
        if (t.indexOf("bottom") >= 0) return "bottom"
        if (t.indexOf("left") >= 0) return "left"
        if (t.indexOf("right") >= 0) return "right"
        return ""
    }

    function locate() {
        var item = root.anchorItem
        if (!item) return
        var scr = item.screen
        var sw = scr ? scr.width : 1920
        root.screenW = sw
        var sh = scr ? scr.height : 1080
        var side = ""
        var qsWin = null
        var win = null

        // 1. the bar window knows which edges it is attached to
        try { qsWin = item.QsWindow.window } catch (e0) { qsWin = null }
        try { win = qsWin ? qsWin : item.Window.window } catch (e1) { win = null }
        try {
            var an = win ? win.anchors : null
            if (an) {
                if (root.vertical) {
                    if (an.left && !an.right) side = "left"
                    else if (an.right && !an.left) side = "right"
                } else {
                    if (an.top && !an.bottom) side = "top"
                    else if (an.bottom && !an.top) side = "bottom"
                }
            }
        } catch (e2) { side = "" }

        // 2. the shell's bar object may say it outright
        if (side === "" && root.barObject) {
            var names = ["position", "barPosition", "edge", "side", "location", "placement", "barSide"]
            for (var i = 0; i < names.length && side === ""; i++) {
                var got = ""
                try { got = root.sideFromText(root.barObject[names[i]]) } catch (e3) { got = "" }
                if ((root.vertical && (got === "left" || got === "right"))
                        || (!root.vertical && (got === "top" || got === "bottom")))
                    side = got
            }
        }

        // 3. last resort: which half of the screen (only meaningful when the bar
        //    window is as big as the screen)
        var pos = item.mapToItem(null, 0, 0)
        if (side === "") {
            if (root.vertical) side = pos.x < sw / 2 ? "left" : "right"
            else side = pos.y < sh / 2 ? "top" : "bottom"
        }
        root.barAtTop = side === "top"
        root.barAtLeft = side === "left"

        // Anchor rectangle on the bar window's outer edge (window coordinates).
        var ww = (win && win.width > 0) ? win.width : 0
        var wh = (win && win.height > 0) ? win.height : 0
        var small = root.vertical ? (ww > 0 && ww < sw * 0.5) : (wh > 0 && wh < sh * 0.5)
        root.useRect = !!qsWin && small
        root.anchorWin = qsWin
        if (root.useRect) {
            if (root.vertical) {
                root.rectW = 1
                root.rectH = Math.max(1, item.height)
                root.rectY = pos.y
                root.rectX = side === "left" ? Math.max(0, ww - 1) : 0
            } else {
                root.rectW = Math.max(1, item.width)
                root.rectH = 1
                root.rectX = pos.x
                root.rectY = side === "top" ? Math.max(0, wh - 1) : 0
            }
            root.extra = 0
        } else {
            root.extra = 6                    // only the widget is known: allow a little for bar padding
        }

        // Tallest the panel may be and still fit between the bar and the far edge.
        var thick = (!root.vertical && wh > 0 && wh < sh * 0.5) ? wh : 40
        var room = root.vertical ? sh - 40 : sh - thick - root.gap - root.extra - 16
        root.maxHeight = Math.max(300, room)
    }

    function justClosed() { return Date.now() - root.grabClosedAt < 500 }

    // ---- click outside to close -----------------------------------------------------
    // Hyprland's focus grab reports any click outside the panel. It is created at
    // runtime so a shell without that module simply keeps the X button and Esc.
    property var grab: null
    property double grabClosedAt: 0
    property double shownAt: 0

    Timer {
        id: regrabTimer
        interval: 120
        repeat: false
        onTriggered: if (root.grab && root.visible) root.grab.active = true
    }

    Component.onCompleted: {
        try {
            var g = Qt.createQmlObject(
                'import Quickshell.Hyprland\nHyprlandFocusGrab { }', root, "OmatravelFocusGrab")
            g.windows = [root]
            g.cleared.connect(function() {
                // A grab lost right after opening is the compositor settling focus (for
                // example the pop-out window closing on an empty workspace), not a click
                // outside: keep the panel open and arm the grab again.
                if (root.open && Date.now() - root.shownAt < 600) {
                    regrabTimer.restart()
                    return
                }
                root.grabClosedAt = Date.now()
                root.visible = false
                root.closeRequested()
            })
            root.grab = g
        } catch (e) {
            root.grab = null
        }
    }


    // ---- window geometry -------------------------------------------------------
    visible: false
    color: "transparent"
    implicitWidth: contentWidth + root.padLeft + root.padRight
    implicitHeight: contentHeight + root.padTop + root.padBottom

    anchor.item: root.useRect ? null : root.anchorItem
    anchor.window: root.useRect ? root.anchorWin : null
    anchor.rect.x: root.rectX
    anchor.rect.y: root.rectY
    anchor.rect.width: root.rectW
    anchor.rect.height: root.rectH
    // The panel opens on the side of the anchor facing away from the bar.
    anchor.edges: root.vertical ? (root.barAtLeft ? Edges.Right : Edges.Left)
                                : (root.barAtTop ? Edges.Bottom : Edges.Top)
    anchor.gravity: root.vertical ? (root.barAtLeft ? Edges.Right : Edges.Left)
                                  : (root.barAtTop ? Edges.Bottom : Edges.Top)
    // Only slide along the bar, never across it, so the panel can't be pushed onto the bar.
    anchor.adjustment: root.vertical ? PopupAdjustment.SlideY : PopupAdjustment.SlideX

    onOpenChanged: {
        if (open) { root.locate(); root.visible = true }
        else root.visible = false
    }

    onVisibleChanged: {
        if (root.visible) root.shownAt = Date.now()
        if (root.grab) Qt.callLater(function() { root.grab.active = root.visible })
        if (root.visible && root.focusTarget)
            Qt.callLater(function() { try { root.focusTarget.forceActiveFocus() } catch (e) { } })
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: root.closeRequested()
    }

    Item {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.padTop
        anchors.bottomMargin: root.padBottom
        anchors.leftMargin: root.padLeft
        anchors.rightMargin: root.padRight

        Item {
            id: holder
            anchors.fill: parent
            clip: true
        }

        Rectangle {                           // the thin border, drawn over the content
            anchors.fill: parent
            z: 10
            color: "transparent"
            radius: root.frameRadius
            border.width: 1
            border.color: root.borderColor
        }
    }
}
