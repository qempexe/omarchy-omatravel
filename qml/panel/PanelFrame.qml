import QtQuick
import Quickshell
import qs.Commons

// the popup the atlas lives in when docked: thin border, round corners, flush against
// the bar's outer edge so it never covers it. closes on esc, x or a click outside.
// children go inside the frame, so Panel.qml can move its content to a window and back
PopupWindow {
    id: root

    property bool open: false                 // follows Panel.opened
    property var anchorItem: null
    property bool vertical: false             // bar on the left / right edge
    property real wantedWidth: 1180
    property real wantedHeight: 760
    property color borderColor: "#33ffffff"   // the outline in one color
    property var borderStops: []               // or a gradient through these, at borderAngle
    property real borderAngle: 0
    property color fillColor: "transparent"    // the background, drawn with the outline as one shape
    property real frameRadius: 12
    property var focusTarget: null            // gets the keyboard when shown
    signal closeRequested()

    default property alias content: holder.data

    readonly property real contentWidth: Math.max(480, Math.min(wantedWidth, screenW - 40))
    readonly property real contentHeight: Math.min(wantedHeight, maxHeight)

    // placement, never over the bar
    // worked out every time it opens, the bar's position isn't known yet at load.
    // anchored to the bar window's outer edge (not the widget inside its padding), and the gap
    // is transparent padding in the popup, so it works whatever the compositor does with margins
    property var barObject: null              // the shell's bar, hint for its edge
    property bool barAtTop: true              // horizontal bar: top (else bottom)
    property bool barAtLeft: true             // vertical bar: left (else right)
    property bool useRect: false              // anchor to the bar window's edge
    property var anchorWin: null
    property real rectX: 0
    property real rectY: 0
    property real rectW: 1
    property real rectH: 1
    property real extra: 0                    // extra room when only the widget is known
    property real screenW: 1920
    property real maxHeight: 620
    readonly property int gap: 0              // gap between bar and panel (0 = flush)
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
        var side = ""
        var qsWin = null
        var win = null

        // 1. the bar window knows its edges
        try { qsWin = item.QsWindow.window } catch (e0) { qsWin = null }
        try { win = qsWin ? qsWin : item.Window.window } catch (e1) { win = null }
        var scr = null
        try { scr = win && win.screen ? win.screen : null } catch (e4) { scr = null }
        var sw = scr && scr.width > 0 ? scr.width : 1920
        root.screenW = sw
        var sh = scr && scr.height > 0 ? scr.height : 1080
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

        // 2. the bar object may just say it
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

        // 3. last resort: which half of the screen (only useful when the bar window is screen sized)
        var pos = item.mapToItem(null, 0, 0)
        if (side === "") {
            if (root.vertical) side = pos.x < sw / 2 ? "left" : "right"
            else side = pos.y < sh / 2 ? "top" : "bottom"
        }
        root.barAtTop = side === "top"
        root.barAtLeft = side === "left"

        // Anchor rectangle on the bar's outer edge (window coordinates).
        var ww = (win && win.width > 0) ? win.width : 0
        var wh = (win && win.height > 0) ? win.height : 0
        var small = root.vertical ? (ww > 0 && ww < sw * 0.5) : (wh > 0 && wh < sh * 0.5)
        // Omarchy 4.5 and later: the bar window spans its screen and the bar is a strip
        // at its edge, so the panel hangs off the outer edge of that strip
        var spans = !!qsWin && !small && (root.vertical ? ww >= sw * 0.5 : wh >= sh * 0.5)
        // how thick the strip is: what the bar window keeps free (a notch or a floating bar
        // makes it more than the bar's size), else the bar's size
        var ez = 0
        try { ez = win && typeof win.exclusiveZone === "number" && win.exclusiveZone > 0 && win.exclusiveZone < (root.vertical ? sw : sh) * 0.5 ? win.exclusiveZone : 0 } catch (e5) { ez = 0 }
        var bs = Math.max(ez, root.barObject && typeof root.barObject.barSize === "number" && root.barObject.barSize > 0 ? root.barObject.barSize : 0)
        var thick = small ? (root.vertical ? ww : wh) : 40
        root.useRect = !!qsWin && (small || spans)
        root.anchorWin = qsWin
        if (root.useRect) {
            if (root.vertical) {
                // the strip ends past the widget, and is at least as thick as the bar
                var tv = small ? ww : Math.max(bs, side === "left" ? pos.x + item.width : ww - pos.x)
                root.rectW = 1
                root.rectH = Math.max(1, item.height)
                root.rectY = pos.y
                root.rectX = side === "left" ? Math.max(0, tv - 1) : Math.max(0, ww - tv)
                thick = tv
            } else {
                var th = small ? wh : Math.max(bs, side === "top" ? pos.y + item.height : wh - pos.y)
                root.rectW = Math.max(1, item.width)
                root.rectH = 1
                root.rectX = pos.x
                root.rectY = side === "top" ? Math.max(0, th - 1) : Math.max(0, wh - th)
                thick = th
            }
            root.extra = 0
        } else {
            root.extra = 6                    // only the widget is known: allow a little for bar padding
        }

        // Set the anchor here rather than with bindings: Quickshell unsets the anchor's
        // item whenever its window is written, and the other way round, so two bindings
        // can undo each other and leave the panel with nothing to hang off.
        if (root.useRect) root.anchor.window = qsWin
        else root.anchor.item = item

        // tallest it can be and still fit between the bar and the far edge
        var room = root.vertical ? sh - 40 : sh - thick - root.gap - root.extra - 16
        root.maxHeight = Math.max(300, room)
    }

    function css(c) {
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a + ")"
    }

    // a rounded rectangle path, the same one for the fill and the outline
    function roundRect(ctx, x, y, w, h, radius) {
        const r = Math.max(0, Math.min(radius, w / 2, h / 2))
        ctx.beginPath()
        ctx.moveTo(x + r, y)
        ctx.arcTo(x + w, y, x + w, y + h, r)
        ctx.arcTo(x + w, y + h, x, y + h, r)
        ctx.arcTo(x, y + h, x, y, r)
        ctx.arcTo(x, y, x + w, y, r)
        ctx.closePath()
    }

    function justClosed() { return Date.now() - root.grabClosedAt < 500 }

    // click outside to close
    // hyprland's focus grab reports clicks outside. made at runtime, so a shell without
    // that module just keeps x and esc
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
                // grab lost right after opening = compositor settling focus (like the pop-out window
                // closing on an empty workspace), not a click outside. keep it open, grab again
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


    // window geometry
    visible: false
    color: "transparent"
    implicitWidth: contentWidth + root.padLeft + root.padRight
    implicitHeight: contentHeight + root.padTop + root.padBottom

    anchor.rect.x: root.rectX
    anchor.rect.y: root.rectY
    anchor.rect.width: root.rectW
    anchor.rect.height: root.rectH
    // opens on the side of the anchor away from the bar
    anchor.edges: root.vertical ? (root.barAtLeft ? Edges.Right : Edges.Left)
                                : (root.barAtTop ? Edges.Bottom : Edges.Top)
    anchor.gravity: root.vertical ? (root.barAtLeft ? Edges.Right : Edges.Left)
                                  : (root.barAtTop ? Edges.Bottom : Edges.Top)
    // only slide along the bar, never across, so it can't end up on the bar
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

        // the background and the outline come from the same rounded rectangle, so the
        // line always sits exactly on the edge of the fill, whatever the size, corners or
        // scale. the outline is half a pixel in, so its one pixel lands on whole pixels
        Canvas {
            id: fill
            anchors.fill: parent
            readonly property color c: root.fillColor
            readonly property real r: root.frameRadius
            onCChanged: requestPaint()
            onRChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (width < 2 || height < 2) return
                root.roundRect(ctx, 0, 0, width, height, r)
                ctx.fillStyle = root.css(c)
                ctx.fill()
            }
        }

        Item {
            id: holder
            anchors.fill: parent
            clip: true
        }

        Canvas {
            id: line
            anchors.fill: parent
            z: 10
            readonly property color c: root.borderColor
            readonly property var stops: root.borderStops
            readonly property real angle: root.borderAngle
            readonly property real r: root.frameRadius
            onCChanged: requestPaint()
            onStopsChanged: requestPaint()
            onAngleChanged: requestPaint()
            onRChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (width < 4 || height < 4) return
                const n = stops ? stops.length : 0
                if (n > 1) {
                    // the window border's gradient, across the panel at its angle
                    const a = angle * Math.PI / 180, dx = Math.cos(a), dy = Math.sin(a)
                    const half = (Math.abs(dx) * width + Math.abs(dy) * height) / 2
                    const g = ctx.createLinearGradient(width / 2 - dx * half, height / 2 - dy * half,
                                                       width / 2 + dx * half, height / 2 + dy * half)
                    for (let i = 0; i < n; i++) g.addColorStop(i / (n - 1), stops[i])
                    ctx.strokeStyle = g
                } else {
                    ctx.strokeStyle = root.css(c)
                }
                ctx.lineWidth = 1
                root.roundRect(ctx, 0.5, 0.5, width - 1, height - 1, Math.max(0, r - 0.5))
                ctx.stroke()
            }
        }
    }
}
