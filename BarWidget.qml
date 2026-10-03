import QtQuick
import Quickshell
import qs.Ui

BarWidget {
    id: root
    moduleName: "io.github.qempexe.omatravel"

    readonly property bool opened: panelLoader.item
        ? panelLoader.item.opened === true
        : false

    readonly property bool popoutSwitchClosing: panelLoader.item
        ? panelLoader.item.popoutSwitchClosing === true
        : false

    // While the panel is popped out into its own window, the bar button docks it back.
    function open() {
        if (!panelLoader.item) return
        if (panelLoader.item.detached) panelLoader.item.reattach()
        else panelLoader.item.open()
    }
    function close() { if (panelLoader.item) panelLoader.item.close() }
    function toggle() {
        if (!panelLoader.item) return
        if (panelLoader.item.detached) panelLoader.item.reattach()
        else panelLoader.item.toggle()
    }
    function closeForPopoutSwitch() {
        if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
    }

    function injectPanel() {
        if (!panelLoader.item) return
        panelLoader.item.bar = root.bar
        panelLoader.item.anchorItem = button
        panelLoader.item.hostWidget = root
        panelLoader.item.travelModel = travelModel
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    onBarChanged: injectPanel()

    TravelModel { id: travelModel }

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("Panel.qml")
        visible: false
        onLoaded: {
            root.injectPanel()
            Qt.callLater(root.injectPanel)
        }
    }

    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: travelModel.displayIcon + " " + travelModel.countryCount
              + " · " + travelModel.cityCount
        tooltipText: travelModel.tooltipText()
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.LeftButton) root.toggle()
        }
    }
}
