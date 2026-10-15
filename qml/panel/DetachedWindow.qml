import QtQuick
import Quickshell

// window for the atlas when it's popped out of the bar. Panel.qml moves its content
// into contentItem and back
FloatingWindow {
    signal closedByUser()

    // the window manager closing it (title bar x, super+q) just hides it
    onVisibleChanged: if (!visible) closedByUser()
}
