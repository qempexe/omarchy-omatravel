import QtQuick
import Quickshell

// Standalone window that hosts the Omatravel panel when it is popped out of the bar.
// Panel.qml moves its content item into `contentItem` and back again.
FloatingWindow {
    signal closedByUser()

    // The window manager closing the window (title-bar ✕, Super+Q …) hides it.
    onVisibleChanged: if (!visible) closedByUser()
}
