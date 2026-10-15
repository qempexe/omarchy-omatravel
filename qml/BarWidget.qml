import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "core"

BarWidget {
    id: root
    moduleName: "io.github.qempexe.omatravel"

    // settings: my own edits (settingsStore) win over setting()
    SettingsStore { id: settingsStore }

    function v(key, fallback) {
        var o = settingsStore.values[key]
        return o !== undefined ? o : fallback
    }

    // the shell's setting() values, used when the panel hasn't set a key
    readonly property var shellDefaults: ({
        icon: setting("icon", "\ud83c\udf0d"),
        showCounts: setting("showCounts", true),
        clickAction: setting("clickAction", "panel"),
        middleAction: setting("middleAction", "none"),
        maxTooltipCountries: setting("maxTooltipCountries", 8),
        maxTooltipCities: setting("maxTooltipCities", 10),
        showFlags: setting("showFlags", true),
        showPath: setting("showPath", true),
        showPlaces: setting("showPlaces", true),
        theme: setting("theme", "auto"),
        customBg: setting("customBg", "#1a1b26"),
        customFg: setting("customFg", "#c0caf5"),
        accentColor: setting("accentColor", "#7aa2f7"),
        opacity: setting("opacity", 100),
        cornerRadius: setting("cornerRadius", 12),
        outline: setting("outline", false),
        surfaceTint: setting("surfaceTint", 0),
        fontScale: setting("fontScale", 100),
        density: setting("density", "comfortable"),
        openAs: setting("openAs", "panel"),
        windowWidth: setting("windowWidth", 1180),
        windowHeight: setting("windowHeight", 760)
    })

    readonly property string cfgClick: String(v("clickAction", shellDefaults.clickAction))
    readonly property string cfgMiddle: String(v("middleAction", shellDefaults.middleAction))

    readonly property bool isVertical: {
        var b = root.bar
        if (!b) return false
        try { return b.vertical === true || b.isVertical === true } catch (e) { return false }
    }

    readonly property bool opened: panelLoader.item
        ? panelLoader.item.opened === true
        : false

    readonly property bool popoutSwitchClosing: panelLoader.item
        ? panelLoader.item.popoutSwitchClosing === true
        : false

    // popped out: the bar icon shows/hides the window, only Dock in the header brings it back
    function open() { if (panelLoader.item) panelLoader.item.showAtlas() }
    function close() { if (panelLoader.item) panelLoader.item.close() }
    function toggle() { if (panelLoader.item) panelLoader.item.toggleAtlas() }
    function closeForPopoutSwitch() {
        if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
    }

    // settings are the last tab of the atlas
    function openSettings() {
        if (!panelLoader.item) return
        panelLoader.item.currentTab = "look"
        panelLoader.item.showAtlas()
    }

    function act(name) {
        if (name === "panel") toggle()
        else if (name === "settings") openSettings()
    }

    function injectPanel() {
        if (!panelLoader.item) return
        panelLoader.item.bar = root.bar
        panelLoader.item.anchorItem = button
        panelLoader.item.hostWidget = root
        panelLoader.item.travelModel = travelModel
        panelLoader.item.vertical = root.isVertical
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    onBarChanged: injectPanel()

    TravelModel {
        id: travelModel
        settings: settingsStore
        fallbacks: root.shellDefaults
    }

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("panel/Panel.qml")
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
        text: travelModel.display.showCounts
              ? travelModel.displayIcon + " " + travelModel.countryCount + " \u00b7 " + travelModel.cityCount
              : travelModel.displayIcon
        tooltipText: travelModel.tooltipText() + "\n\nRight-click for settings"
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.LeftButton) root.act(root.cfgClick)
            else if (buttonCode === Qt.MiddleButton) root.act(root.cfgMiddle)
            else if (buttonCode === Qt.RightButton) root.openSettings()
        }
    }
}
