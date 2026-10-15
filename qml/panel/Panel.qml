pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "../globe"
import "../controls"

// layout: header on top, globe on the left, tabbed sidebar on the right,
// add a place form at the bottom of it
Panel {
    id: root
    moduleName: "io.github.qempexe.omatravel"
    manageIpc: false

    // set by BarWidget
    property var anchorItem: null
    property var hostWidget: null
    property var travelModel: null
    property bool vertical: false             // bar on the left / right edge

    property string currentTab: "places"
    readonly property var atlasLook: tm ? tm.look : ({ opacity: 100, cornerRadius: 12, outline: false, surfaceTint: 0,
        fontScale: 100, density: "comfortable", openAs: "panel", windowWidth: 1180, windowHeight: 760 })
    // the one inset used on every edge (settings > look > spacing)
    readonly property int gutter: atlasLook.density === "compact" ? 10 : (atlasLook.density === "spacious" ? 18 : 14)
    property string query: ""
    property bool helpVisible: false
    property string newCountry: ""
    property string newCity: ""
    property string newCityDate: ""
    property string newCityForCountry: ""
    property bool addAsWishlist: false
    property string newProfile: ""

    // pop out: the whole card lives in the bar popup or in its own window
    property bool detached: false             // popped out, until Dock
    // colors: one palette for the popup and the window
    // named theme      -> that theme
    // follow omarchy   -> live omarchy colors, re-read when the theme changes
    // no omarchy file  -> the shell's bar colors (made opaque)
    // nothing here depends on `detached`, so both look the same
    readonly property bool useBarColors: !tm || (tm.activeTheme === "auto" && tm.systemTheme === null)
    readonly property bool followSystem: !!tm && tm.activeTheme === "auto" && tm.systemTheme !== null
    readonly property color fg: useBarColors && root.barForeground !== undefined
        ? root.barForeground : (tm ? tm.themeText : "#e8dcc8")
    readonly property color baseBg: {
        if (useBarColors && root.barBackground !== undefined) {
            var c = root.barBackground
            return Qt.rgba(c.r, c.g, c.b, 1)          // bar colors can be translucent, the base never is
        }
        return tm ? tm.themeBackground : Qt.rgba(0.10, 0.09, 0.08, 1)
    }
    // solid background with some accent over it (settings > look > window tint)
    readonly property color panelBg: {
        var t = root.atlasLook.surfaceTint / 100
        var b = root.baseBg, a = root.accent
        return Qt.rgba(b.r + (a.r - b.r) * t, b.g + (a.g - b.g) * t, b.b + (a.b - b.b) * t, 1)
    }
    // what's actually painted behind the content (settings > look > opacity)
    readonly property color paintBg: Qt.rgba(panelBg.r, panelBg.g, panelBg.b, atlasLook.opacity / 100)
    // tell the model the shell's color so it can tell which omarchy theme is on
    Binding { target: root.tm; property: "shellBg"; value: root.barBackground; when: !!root.tm }

    property var _home: null          // the popup's content item, kept while the card is in the window

    readonly property var tm: travelModel
    readonly property color accent: tm ? tm.themeAccent : "#d4a35a"
    readonly property color wishColor: "#cba6f7"
    // one compact type scale, from the shell's body size
    readonly property int fsMain: Math.max(8, Math.round(Math.max(10, Style.font.body * 0.9) * atlasLook.fontScale / 100))
    readonly property int fsSub:  Math.max(7, Math.round(Math.max(9,  Style.font.body * 0.8) * atlasLook.fontScale / 100))

    readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    readonly property color dim: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.56)
    readonly property color faint: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
    readonly property color hoverFill: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)
    readonly property color selectedFill: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)

    readonly property var controlSections: [
        { title: "GLOBE", controls: [
            { input: "DRAG / FLICK", action: "Spin the globe" },
            { input: "WHEEL", action: "Zoom (labels load as you zoom)" },
            { input: "CLICK CITY", action: "Prefill the add form" },
            { input: "+ / − / ⌖", action: "Zoom in, out, recentre" },
            { input: "STATS · YEAR", action: "Show the map as of the end of a year" }
        ] },
        { title: "PLACES", controls: [
            { input: "CLICK COUNTRY", action: "Select it and show its cities" },
            { input: "CLICK CITY CHIP", action: "Fly to it on the globe" },
            { input: "DATE", action: "YYYY, YYYY-MM or YYYY-MM-DD adds it to the path" },
            { input: "SEARCH", action: "Filter your countries and cities" },
            { input: "WISH ✓", action: "Move a wishlist city to visited" },
            { input: "STATS · EXPORT", action: "Save your places as CSV or JSON" },
            { input: "ESC", action: "Close" }
        ] }
    ]

    // pop out / dock
    // `detached` is what you picked in the header and it sticks: popped out, the bar icon
    // shows/hides the window, and closing it (x, super+q) only hides it. only Dock goes back
    // to the popup. the window exists exactly while it's wanted, so the icon never does nothing
    property bool windowRequested: false
    property bool inWindow: false                  // the card is in the window right now
    readonly property bool windowShown: root.inWindow && root.windowRequested

    function _showWindow() {
        if (tm) tm.ensureIndex()
        root.windowRequested = true
        detachLoader.active = true                 // DetachedWindow calls _enterWindow() once it exists
    }

    function _hideWindow() {
        root._leaveWindow()
        root.windowRequested = false
        detachLoader.active = false                // destroys the window
    }

    function _enterWindow(win) {
        if (!win || root.inWindow) return
        if (!root._home) root._home = card.parent
        card.parent = win.contentItem
        root.inWindow = true
    }

    // card always goes back to the popup before the window is destroyed
    function _leaveWindow() {
        if (!root.inWindow) return
        if (root._home) card.parent = root._home
        root.inWindow = false
    }

    // window manager closed it: forget it, stay popped out.
    // until pop out / dock is used, settings > window > open as decides where the icon opens
    property bool userPicked: false

    function _chooseMode() {
        if (root.userPicked) return
        var want = root.atlasLook.openAs === "window"
        if (want === root.detached) return
        if (root.windowRequested) root._hideWindow()
        if (root.opened) root.controller.hide()
        root.detached = want
    }

    function _windowClosedByUser() {
        if (!root.windowRequested) return
        root._leaveWindow()
        root.windowRequested = false
        Qt.callLater(function() { if (!root.windowRequested) detachLoader.active = false })
    }

    // bar -> window
    function detach() {
        root.detached = true
        root.helpVisible = false
        root._wantPanel = false
        panelCheck.stop()
        root.controller.hide()                     // close the bar popup
        root._showWindow()
    }

    // window -> bar. popup only opens once the window is really gone: with nothing else on
    // screen hyprland moves focus on close and the popup would lose its grab and close
    function dock() {
        root._hideWindow()
        root.detached = false
        dockShowTimer.restart()
    }

    // popup still not open shortly after docking? pop the window back out instead of nothing
    property bool _wantPanel: false

    function _openPanel() {
        root._wantPanel = true
        root.controller.show()
        panelCheck.restart()
    }

    onOpenedChanged: if (root.opened) {
        if (tm) tm.ensureIndex()
        root._wantPanel = false
        panelCheck.stop()
    }

    Timer {
        id: dockShowTimer
        interval: 200
        repeat: false
        onTriggered: if (!root.detached && !root.opened) root._openPanel()
    }

    Timer {
        id: panelCheck
        interval: 600
        repeat: false
        onTriggered: if (root._wantPanel && !root.opened && !root.detached) {
            root._wantPanel = false
            console.warn("Omatravel: the docked panel did not open; showing the window instead")
            root.detach()
        }
    }

    // for BarWidget: what the icon does in each mode
    function showAtlas() {
        root._chooseMode()
        if (root.detached) root._showWindow()
        else if (!root.opened && !root.recentlyClosed()) root.controller.show()
    }
    function toggleAtlas() {
        root._chooseMode()
        if (root.detached) {
            if (root.windowShown) root._hideWindow()
            else root._showWindow()
        } else if (!root.recentlyClosed()) {
            root.toggle()
        }
    }

    // true for a moment after a click outside closed the panel,
    // so that same click on the bar button doesn't open it again
    function recentlyClosed() { return panel.justClosed() }

    function open()  { root.controller.show() }
    function close() {
        root.controller.hide()
        if (root.windowRequested) root._hideWindow()
    }
    function switchPanel(direction) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function")
            return root.bar.switchPanelFrom(root.hostWidget || root, direction)
        return false
    }

    function filteredCountries() {
        var rows = root.tm ? root.tm.countries : []
        var q = root.query.trim().toLowerCase()
        if (!q) return rows
        return rows.filter(function(r) {
            if (r.name.toLowerCase().indexOf(q) >= 0) return true
            for (var i = 0; i < r.cities.length; i++)
                if (r.cities[i].toLowerCase().indexOf(q) >= 0) return true
            return false
        })
    }

    function doAddCountry() {
        if (!tm || !root.newCountry.trim()) return
        var name = tm.canonicalCountry(root.newCountry)
        tm.addCountry(name)
        root.newCityForCountry = name
        root.newCountry = ""
        countryField.clear()
        cityField.forceFocus()
    }

    function doAddCity() {
        if (!tm) return
        var ok = root.addAsWishlist
            ? tm.addWishlist(root.newCityForCountry, root.newCity)
            : tm.addCity(root.newCityForCountry, root.newCity, root.newCityDate)
        if (ok) {
            root.newCity = ""
            root.newCityDate = ""
            cityField.clear()
            dateField.clear()
        }
    }

    LazyLoader {
        id: detachLoader
        active: false

        DetachedWindow {
            id: dwin
            visible: true
            title: "Omatravel"
            color: root.atlasLook.opacity < 100 ? "transparent" : root.panelBg
            implicitWidth: Style.space(root.atlasLook.windowWidth)
            implicitHeight: Style.space(root.atlasLook.windowHeight)
            onClosedByUser: root._windowClosedByUser()
            Component.onCompleted: root._enterWindow(dwin)
        }
    }

    PanelFrame {
        id: panel
        anchorItem: root.anchorItem
        barObject: root.bar
        vertical: root.vertical
        open: root.opened
        focusTarget: keyCatcher
        borderColor: root.atlasLook.outline ? root.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.14)
        frameRadius: root.atlasLook.cornerRadius
        wantedWidth: Style.space(root.atlasLook.windowWidth)
        wantedHeight: Style.space(root.atlasLook.windowHeight)
        onCloseRequested: root.close()

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) { root.switchPanel(direction) }
        }

        Item {
            id: card
            x: 0; y: 0
            width: parent ? parent.width : 0
            height: parent ? parent.height : 0

            Rectangle {                      // same solid background in the popup and the window
                anchors.fill: parent
                z: -1
                radius: root.inWindow ? 0 : root.atlasLook.cornerRadius
                color: root.paintBg
            }

            // ---- header ----
            Item {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Style.space(84)
                z: 2

                Rectangle {                          // the header card
                    anchors.fill: parent
                    anchors.margins: root.gutter
                    radius: Style.space(12)
                    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
                }

                Rectangle {                          // round badge: ring with a dot
                    id: avatar
                    anchors.left: parent.left
                    anchors.leftMargin: root.gutter + Style.space(12)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Style.space(34)
                    height: width
                    radius: width / 2
                    color: root.selectedFill
                    border.width: 1
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.7)
                    Rectangle {
                        anchors.centerIn: parent
                        width: Style.space(12)
                        height: width
                        radius: width / 2
                        color: root.accent
                    }
                }

                Column {
                    id: titleBlock
                    anchors.left: avatar.right
                    anchors.leftMargin: Style.space(12)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(2)
                    Text {
                        id: title
                        text: "Omatravel"
                        color: root.fg
                        font.family: root.fontFamily
                        font.pixelSize: root.fsMain + 2
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }
                    Text {
                        text: root.tm
                              ? root.tm.countryCount + " countries  \u00b7  " + root.tm.cityCount + " cities  \u00b7  " + root.tm.activeProfile
                              : ""
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: root.fsSub
                        textFormat: Text.PlainText
                    }
                }

                FlatButton {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.rightMargin: root.gutter + Style.space(10)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    hPad: Style.space(10)
                    foreground: root.fg
                    accent: root.accent
                    fontFamily: root.fontFamily
                    pixelSize: root.fsMain
                    onClicked: root.close()
                }
                FlatButton {
                    id: helpButton
                    anchors.right: closeButton.left
                    anchors.rightMargin: Style.space(4)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "?"
                    selected: root.helpVisible
                    hPad: Style.space(12)
                    foreground: root.fg
                    accent: root.accent
                    fontFamily: root.fontFamily
                    pixelSize: root.fsMain
                    onClicked: root.helpVisible = !root.helpVisible
                }
                FlatButton {
                    id: detachButton
                    anchors.right: helpButton.left
                    anchors.rightMargin: Style.space(4)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.detached ? "Dock" : "Pop out"
                    hPad: Style.space(12)
                    foreground: root.fg
                    accent: root.accent
                    fontFamily: root.fontFamily
                    pixelSize: root.fsSub
                    onClicked: { root.userPicked = true; root.detached ? root.dock() : root.detach() }
                }
                FlatButton {
                    id: fitButton
                    anchors.right: detachButton.left
                    anchors.rightMargin: Style.space(4)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⌖"
                    hPad: Style.space(10)
                    foreground: root.fg
                    accent: root.accent
                    fontFamily: root.fontFamily
                    pixelSize: root.fsMain + 2
                    onClicked: if (globeLoader.item) globeLoader.item.resetView()
                }
                FieldBox {
                    id: searchField
                    anchors.right: fitButton.left
                    anchors.rightMargin: Style.space(8)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(Style.space(320), card.width * 0.32)
                    height: Style.space(34)
                    placeholderText: "Search your countries or cities"
                    foreground: root.fg
                    accent: root.accent
                    fontFamily: root.fontFamily
                    pixelSize: root.fsMain
                    onTextChanged: {
                        root.query = text
                        if (text && root.currentTab !== "places") root.currentTab = "places"
                    }
                }

            }

            // ---- tabs, full width, selected one underlined ----
            Item {
                id: mainTabs
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                height: Style.space(40)
                z: 2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.gutter
                    anchors.rightMargin: root.gutter
                    spacing: 0

                    Repeater {
                        model: [
                            { key: "places",   label: "Places" },
                            { key: "wishlist", label: "Wishlist" },
                            { key: "stats",    label: "Stats" },
                            { key: "profiles", label: "Profiles" },
                            { key: "look",     label: "Settings" }
                        ]
                        delegate: Item {
                            id: tabItem
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            readonly property bool on: root.currentTab === modelData.key

                            Text {
                                anchors.centerIn: parent
                                text: tabItem.modelData.label
                                color: tabItem.on ? root.fg : root.dim
                                font.family: root.fontFamily
                                font.pixelSize: root.fsSub + 1
                                font.weight: tabItem.on ? Font.DemiBold : Font.Normal
                                textFormat: Text.PlainText
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
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = tabItem.modelData.key
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: root.gutter
                    anchors.rightMargin: root.gutter
                    height: 1
                    color: root.faint
                    z: -1
                }
            }

            // ---- footer ----
            Item {
                id: footer
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Style.space(34)
                z: 2

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 1
                    color: root.faint
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: root.gutter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(8)

                    Rectangle {
                        width: escText.implicitWidth + Style.space(12)
                        height: Style.space(18)
                        radius: 4
                        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            id: escText
                            anchors.centerIn: parent
                            text: "Esc"
                            color: root.fg
                            font.family: root.fontFamily
                            font.pixelSize: root.fsSub - 1
                            textFormat: Text.PlainText
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "close"
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: root.fsSub - 1
                        textFormat: Text.PlainText
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: root.gutter
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.currentTab === "look" ? "Changes apply instantly" : "Right-click the bar icon for settings"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: root.fsSub - 1
                    textFormat: Text.PlainText
                }
            }

            // ---- body ----
            Item {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: mainTabs.bottom
                anchors.bottom: footer.top
                z: 2

                readonly property real sidebarWidth: Math.min(Style.space(440), width * 0.42)

                // map
                Item {
                    id: mapPane
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: body.width - body.sidebarWidth - 1

                    Loader {
                        id: globeLoader
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: mapFooter.top
                        anchors.leftMargin: root.gutter
                        anchors.rightMargin: root.gutter
                        anchors.topMargin: root.gutter
                        active: root.opened || root.windowShown
                        sourceComponent: GlobeView {
                            points: root.tm.globePoints
                            pathPoints: root.tm.pathPoints
                            bands: root.tm.bands
                            showPath: root.tm.display.showPath
                            showPlaces: root.tm.display.showPlaces
                            accent: root.accent
                            textColor: root.fg
                            bgColor: root.panelBg
                            onBandRequested: function(b) { root.tm.requestBand(b) }
                            onPlaceClicked: function(p) {
                                var country = p.country || root.tm.countryNameForCode(p.cc)
                                if (country) root.newCityForCountry = country
                                root.newCity = p.kind === "place" ? p.name : ""
                                cityField.text = root.newCity
                                root.currentTab = "places"
                                cityField.forceFocus()
                            }
                        }
                    }

                    Item {
                        id: mapFooter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Style.space(38)

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: root.gutter
                            anchors.right: stats.left
                            anchors.rightMargin: Style.space(12)
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.tm && root.tm.notice !== ""
                                  ? root.tm.notice
                                  : root.tm && root.tm.viewYear > 0
                                    ? "Showing your trips up to " + root.tm.viewYear + "  ·  change it in Stats"
                                    : "Drag to spin  ·  scroll to zoom  ·  click a city"
                            color: root.tm && (root.tm.notice !== "" || root.tm.viewYear > 0) ? root.accent : root.dim
                            font.family: root.fontFamily
                            font.pixelSize: root.fsSub
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                        Text {
                            id: stats
                            anchors.right: parent.right
                            anchors.rightMargin: root.gutter
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.tm
                                  ? root.tm.countryCount + " countries  ·  " + root.tm.cityCount + " cities"
                                    + (root.tm.pathPoints.length > 1
                                       ? "  ·  " + root.tm.pathPoints.length + " dated trips" : "")
                                  : ""
                            color: root.dim
                            font.family: root.fontFamily
                            font.pixelSize: root.fsSub
                            textFormat: Text.PlainText
                        }
                    }
                }

                Rectangle {
                    x: mapPane.width
                    width: 1
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    color: root.faint
                }

                // sidebar
                Item {
                    id: sidebar
                    width: body.sidebarWidth
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    readonly property bool narrow: width < Style.space(340)

                    // tab content
                    Item {
                        id: content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: addPanel.visible ? addPanel.height : 0
                        clip: true

                        // ---- places ----
                        ListView {
                            id: countryList
                            anchors.fill: parent
                            visible: root.currentTab === "places"
                            clip: true
                            topMargin: Style.space(12)
                            bottomMargin: Style.space(12)
                            spacing: Style.space(8)
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.filteredCountries()

                            delegate: Item {
                                id: crow
                                required property var modelData
                                readonly property bool current: root.newCityForCountry === crow.modelData.name
                                width: countryList.width
                                height: placeCard.height

                                Rectangle {
                                    id: placeCard
                                    x: Style.space(14)
                                    width: parent.width - Style.space(28)
                                    height: topRow.height + (detail.visible ? detail.height + Style.space(14) : 0)
                                    radius: Style.space(10)
                                    color: crow.current ? root.selectedFill
                                         : rowMouse.containsMouse ? root.hoverFill : "transparent"
                                    border.width: 1
                                    border.color: crow.current
                                        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6)
                                        : root.faint

                                    Item {
                                        id: topRow
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        height: Style.space(60)

                                        MouseArea {
                                            id: rowMouse
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.right: removeBtn.left
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.newCityForCountry = crow.current ? "" : crow.modelData.name
                                        }

                                        Text {
                                            id: flagText
                                            visible: root.tm.display.showFlags
                                            anchors.left: parent.left
                                            anchors.leftMargin: Style.space(14)
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: crow.modelData.flag
                                            font.pixelSize: root.fsMain + 6
                                            textFormat: Text.PlainText
                                        }

                                        Column {
                                            anchors.left: flagText.visible ? flagText.right : parent.left
                                            anchors.leftMargin: Style.space(flagText.visible ? 10 : 14)
                                            anchors.right: countBadge.left
                                            anchors.rightMargin: Style.space(8)
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Style.space(3)

                                            Text {
                                                width: parent.width
                                                text: crow.modelData.name
                                                color: root.fg
                                                font.family: root.fontFamily
                                                font.pixelSize: root.fsMain
                                                font.bold: true
                                                elide: Text.ElideRight
                                                textFormat: Text.PlainText
                                            }
                                            Text {
                                                width: parent.width
                                                text: crow.modelData.cities.length > 0
                                                      ? crow.modelData.cities.join(", ") : "No cities yet"
                                                color: root.dim
                                                font.family: root.fontFamily
                                                font.pixelSize: root.fsSub
                                                elide: Text.ElideRight
                                                textFormat: Text.PlainText
                                            }
                                        }

                                        Rectangle {
                                            id: countBadge
                                            anchors.right: removeBtn.left
                                            anchors.rightMargin: Style.space(4)
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: Style.space(24)
                                            width: Math.max(height, badgeText.implicitWidth + Style.space(14))
                                            radius: height / 2
                                            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                                            Text {
                                                id: badgeText
                                                anchors.centerIn: parent
                                                text: crow.modelData.cityCount
                                                color: root.accent
                                                font.family: root.fontFamily
                                                font.pixelSize: root.fsSub
                                                font.bold: true
                                                textFormat: Text.PlainText
                                            }
                                        }

                                        FlatButton {
                                            id: removeBtn
                                            anchors.right: parent.right
                                            anchors.rightMargin: Style.space(8)
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "✕"
                                            hPad: Style.space(8)
                                            foreground: root.fg
                                            accent: root.accent
                                            fontFamily: root.fontFamily
                                            pixelSize: root.fsSub
                                            onClicked: {
                                                if (root.newCityForCountry === crow.modelData.name)
                                                    root.newCityForCountry = ""
                                                root.tm.removeCountry(crow.modelData.name)
                                            }
                                        }
                                    }

                                    Column {
                                        id: detail
                                        visible: crow.current && crow.modelData.cityItems.length > 0
                                        anchors.left: parent.left
                                        anchors.leftMargin: Style.space(14)
                                        anchors.right: parent.right
                                        anchors.rightMargin: Style.space(14)
                                        anchors.top: topRow.bottom
                                        spacing: Style.space(10)

                                        Flow {
                                            id: chips
                                            width: parent.width
                                            spacing: Style.space(6)

                                            Repeater {
                                                model: crow.modelData.cityItems
                                                delegate: Rectangle {
                                                    id: chip
                                                    required property var modelData
                                                    height: Style.space(28)
                                                    width: chipRow.implicitWidth + Style.space(20)
                                                    radius: height / 2
                                                    color: "transparent"
                                                    border.width: 1
                                                    border.color: Qt.rgba(root.fg.r, root.fg.g,
                                                                          root.fg.b, 0.28)
                                                    opacity: chip.modelData.pinned ? 1 : 0.55

                                                    Row {
                                                        id: chipRow
                                                        anchors.centerIn: parent
                                                        spacing: Style.space(8)
                                                        Text {
                                                            text: chip.modelData.name
                                                                  + (chip.modelData.visits.length > 1 ? " ×" + chip.modelData.visits.length : "")
                                                                  + (chip.modelData.pinned ? "" : " · no pin")
                                                            color: root.fg
                                                            font.family: root.fontFamily
                                                            font.pixelSize: root.fsSub
                                                            textFormat: Text.PlainText
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                enabled: chip.modelData.pinned
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    var p = root.tm.pointFor(crow.modelData.name, chip.modelData.name)
                                                                    if (p && globeLoader.item) globeLoader.item.focusOn(p.lat, p.lng, 9)
                                                                }
                                                            }
                                                        }
                                                        Text {
                                                            text: "✕"
                                                            color: root.fg
                                                            opacity: 0.6
                                                            font.pixelSize: root.fsSub
                                                            textFormat: Text.PlainText
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                anchors.margins: -5
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.tm.removeCity(crow.modelData.name, chip.modelData.name)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // dated visits, one line per city, each removable
                                        Repeater {
                                            model: crow.modelData.cityItems
                                            delegate: Item {
                                                id: visitBlock
                                                required property var modelData
                                                visible: visitBlock.modelData.visits.length > 0
                                                width: detail.width
                                                height: visible ? vcol.height : 0

                                                Column {
                                                    id: vcol
                                                    width: parent.width
                                                    spacing: Style.space(5)
                                                    Text {
                                                        text: visitBlock.modelData.name + " · "
                                                              + (visitBlock.modelData.visits.length === 1
                                                                 ? "visited" : visitBlock.modelData.visits.length + " visits")
                                                        color: root.dim
                                                        font.family: root.fontFamily
                                                        font.pixelSize: root.fsSub
                                                        textFormat: Text.PlainText
                                                    }
                                                    Flow {
                                                        width: parent.width
                                                        spacing: Style.space(5)
                                                        Repeater {
                                                            model: visitBlock.modelData.visits
                                                            delegate: Rectangle {
                                                                id: vchip
                                                                required property string modelData
                                                                height: Style.space(24)
                                                                width: vRow.implicitWidth + Style.space(16)
                                                                radius: height / 2
                                                                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
                                                                Row {
                                                                    id: vRow
                                                                    anchors.centerIn: parent
                                                                    spacing: Style.space(6)
                                                                    Text {
                                                                        text: vchip.modelData
                                                                        color: root.fg
                                                                        font.family: root.fontFamily
                                                                        font.pixelSize: root.fsSub
                                                                        textFormat: Text.PlainText
                                                                    }
                                                                    Text {
                                                                        text: "✕"
                                                                        color: root.fg
                                                                        opacity: 0.6
                                                                        font.pixelSize: root.fsSub
                                                                        textFormat: Text.PlainText
                                                                        MouseArea {
                                                                            anchors.fill: parent
                                                                            anchors.margins: -5
                                                                            cursorShape: Qt.PointingHandCursor
                                                                            onClicked: root.tm.removeVisit(crow.modelData.name,
                                                                                                           visitBlock.modelData.name, vchip.modelData)
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - Style.space(48)
                                visible: countryList.count === 0
                                text: root.query ? "Nothing matches “" + root.query.trim() + "”."
                                                 : "No places yet.\nAdd a country below, then a city."
                                color: root.dim
                                font.family: root.fontFamily
                                font.pixelSize: root.fsMain
                                lineHeight: 1.3
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                            }
                        }

                        // ---- wishlist ----
                        Flickable {
                            anchors.fill: parent
                            visible: root.currentTab === "wishlist"
                            contentHeight: wishCol.height + Style.space(24)
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: wishCol
                                x: Style.space(14)
                                y: Style.space(12)
                                width: parent.width - Style.space(28)
                                spacing: Style.space(8)

                                Repeater {
                                    model: root.tm ? root.tm.wishlist : []
                                    delegate: Rectangle {
                                        id: wishRow
                                        required property var modelData
                                        width: wishCol.width
                                        height: wishHead.height + wishFlow.height + Style.space(34)
                                        radius: Style.space(10)
                                        color: "transparent"
                                        border.width: 1
                                        border.color: root.faint

                                        Text {
                                            id: wishHead
                                            anchors.left: parent.left
                                            anchors.leftMargin: Style.space(14)
                                            anchors.top: parent.top
                                            anchors.topMargin: Style.space(14)
                                            text: (root.tm.display.showFlags ? wishRow.modelData.flag + "  " : "")
                                                  + wishRow.modelData.country
                                            color: root.fg
                                            font.family: root.fontFamily
                                            font.pixelSize: root.fsMain
                                            font.bold: true
                                            textFormat: Text.PlainText
                                        }
                                        Flow {
                                            id: wishFlow
                                            anchors.left: parent.left
                                            anchors.leftMargin: Style.space(14)
                                            anchors.right: parent.right
                                            anchors.rightMargin: Style.space(14)
                                            anchors.top: wishHead.bottom
                                            anchors.topMargin: Style.space(10)
                                            spacing: Style.space(6)

                                            Repeater {
                                                model: wishRow.modelData.cities
                                                delegate: Rectangle {
                                                    id: wchip
                                                    required property string modelData
                                                    height: Style.space(28)
                                                    width: wRow.implicitWidth + Style.space(20)
                                                    radius: height / 2
                                                    color: Qt.rgba(root.wishColor.r, root.wishColor.g, root.wishColor.b, 0.08)
                                                    border.width: 1
                                                    border.color: Qt.rgba(root.wishColor.r, root.wishColor.g, root.wishColor.b, 0.7)
                                                    Row {
                                                        id: wRow
                                                        anchors.centerIn: parent
                                                        spacing: Style.space(8)
                                                        Text {
                                                            text: wchip.modelData
                                                            color: root.fg
                                                            font.family: root.fontFamily
                                                            font.pixelSize: root.fsSub
                                                            textFormat: Text.PlainText
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    var p = root.tm.pointFor(wishRow.modelData.country, wchip.modelData, "wishlist")
                                                                    if (p && globeLoader.item) globeLoader.item.focusOn(p.lat, p.lng, 9)
                                                                }
                                                            }
                                                        }
                                                        Text {
                                                            text: "✓"
                                                            color: root.wishColor
                                                            font.pixelSize: root.fsSub
                                                            font.bold: true
                                                            textFormat: Text.PlainText
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                anchors.margins: -5
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.tm.markVisited(wishRow.modelData.country, wchip.modelData)
                                                            }
                                                        }
                                                        Text {
                                                            text: "✕"
                                                            color: root.fg
                                                            opacity: 0.6
                                                            font.pixelSize: root.fsSub
                                                            textFormat: Text.PlainText
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                anchors.margins: -5
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.tm.removeWishlist(wishRow.modelData.country, wchip.modelData)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - Style.space(48)
                                visible: !root.tm || root.tm.wishlist.length === 0
                                text: "Nothing on your wishlist yet.\nSwitch the toggle below to Wishlist and add a city."
                                color: root.dim
                                font.family: root.fontFamily
                                font.pixelSize: root.fsMain
                                lineHeight: 1.3
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                            }
                        }

                        // ---- stats ----
                        Flickable {
                            anchors.fill: parent
                            visible: root.currentTab === "stats"
                            contentHeight: statsCol.height + Style.space(40)
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: statsCol
                                x: Style.space(16)
                                y: Style.space(14)
                                width: parent.width - Style.space(32)
                                spacing: Style.space(10)
                                readonly property var st: root.tm ? root.tm.stats : null

                                Flow {
                                    id: tiles
                                    width: parent.width
                                    spacing: Style.space(8)
                                    readonly property real tileW: Math.floor((width - spacing) / 2)

                                    Repeater {
                                        model: statsCol.st ? [
                                            { big: statsCol.st.sovereign + " / " + 195,
                                              small: "countries · " + statsCol.st.worldPercent + "% of the world" },
                                            { big: statsCol.st.continentCount + " / 7",
                                              small: "continents" },
                                            { big: String(statsCol.st.cities),
                                              small: "cities · " + statsCol.st.visits + " dated visits" },
                                            { big: statsCol.st.distanceKm > 0 ? root.tm.formatKm(statsCol.st.distanceKm) : "—",
                                              small: statsCol.st.distanceKm > 0
                                                     ? statsCol.st.laps + "× around the Earth"
                                                     : "needs two dated cities" }
                                        ] : []
                                        delegate: Rectangle {
                                            id: tile
                                            required property var modelData
                                            width: tiles.tileW
                                            height: Style.space(78)
                                            radius: Style.space(10)
                                            color: root.selectedFill
                                            border.width: 1
                                            border.color: root.faint
                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: Style.space(12)
                                                spacing: Style.space(4)
                                                Text {
                                                    width: parent.width
                                                    text: tile.modelData.big
                                                    color: root.accent
                                                    font.family: root.fontFamily
                                                    font.pixelSize: root.fsMain + 6
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    textFormat: Text.PlainText
                                                }
                                                Text {
                                                    width: parent.width
                                                    text: tile.modelData.small
                                                    color: root.dim
                                                    font.family: root.fontFamily
                                                    font.pixelSize: root.fsSub
                                                    wrapMode: Text.Wrap
                                                    maximumLineCount: 2
                                                    elide: Text.ElideRight
                                                    textFormat: Text.PlainText
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    visible: !!statsCol.st && statsCol.st.continentCount > 0
                                    text: statsCol.st ? statsCol.st.continents.join("  ·  ") : ""
                                    color: root.fg
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fsSub
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                }

                                Item { width: 1; height: Style.space(4) }
                                SectionLabel {
                                    text: "Highlights"
                                    foreground: root.fg
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsSub
                                }
                                Repeater {
                                    model: statsCol.st ? [
                                        { k: "First trip", v: statsCol.st.first || "—" },
                                        { k: "Latest trip", v: statsCol.st.last || "—" },
                                        { k: "Most visited", v: statsCol.st.topCity && statsCol.st.topCity.count > 1
                                              ? statsCol.st.topCity.name + " ×" + statsCol.st.topCity.count : "—" },
                                        { k: "Busiest year", v: statsCol.st.busiestYear
                                              ? statsCol.st.busiestYear.year + " (" + statsCol.st.busiestYear.trips
                                                + (statsCol.st.busiestYear.trips === 1 ? " visit)" : " visits)") : "—" }
                                    ] : []
                                    delegate: Item {
                                        id: hlRow
                                        required property var modelData
                                        width: statsCol.width
                                        height: Style.space(34)
                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: hlRow.modelData.k
                                            color: root.dim
                                            font.family: root.fontFamily
                                            font.pixelSize: root.fsSub
                                            textFormat: Text.PlainText
                                        }
                                        Text {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width * 0.62
                                            horizontalAlignment: Text.AlignRight
                                            text: hlRow.modelData.v
                                            color: root.fg
                                            font.family: root.fontFamily
                                            font.pixelSize: root.fsMain
                                            elide: Text.ElideRight
                                            textFormat: Text.PlainText
                                        }
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 1
                                            color: root.faint
                                        }
                                    }
                                }

                                Item { width: 1; height: Style.space(4) }
                                SectionLabel {
                                    text: "Time travel: show your trips up to…"
                                    foreground: root.fg
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsSub
                                }
                                Flow {
                                    width: parent.width
                                    spacing: Style.space(6)
                                    Repeater {
                                        model: root.tm && root.tm.years.length > 0 ? [0].concat(root.tm.years) : []
                                        delegate: FlatButton {
                                            id: yearBtn
                                            required property int modelData
                                            text: yearBtn.modelData === 0 ? "All" : String(yearBtn.modelData)
                                            outlined: true
                                            selected: root.tm.viewYear === yearBtn.modelData
                                            implicitHeight: Style.space(28)
                                            hPad: Style.space(12)
                                            foreground: root.fg
                                            accent: root.accent
                                            fontFamily: root.fontFamily
                                            pixelSize: root.fsSub
                                            onClicked: root.tm.setViewYear(yearBtn.modelData)
                                        }
                                    }
                                }
                                Text {
                                    width: parent.width
                                    visible: !root.tm || root.tm.years.length === 0
                                    text: "Add a city with a date and the years you travelled appear here."
                                    color: root.dim
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fsSub
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                }
                                Text {
                                    width: parent.width
                                    visible: !!root.tm && root.tm.years.length > 0
                                    text: "The globe and travel path show your map as it stood at the end of that year. Undated cities and your wishlist always stay."
                                    color: root.dim
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fsSub
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                }

                                Item { width: 1; height: Style.space(4) }
                                SectionLabel {
                                    text: "Export this profile"
                                    foreground: root.fg
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsSub
                                }
                                Row {
                                    spacing: Style.space(8)
                                    FlatButton {
                                        text: "Save as CSV"
                                        outlined: true
                                        implicitHeight: Style.space(32)
                                        hPad: Style.space(16)
                                        foreground: root.fg
                                        accent: root.accent
                                        fontFamily: root.fontFamily
                                        pixelSize: root.fsSub
                                        onClicked: root.tm.exportData("csv")
                                    }
                                    FlatButton {
                                        text: "Save as JSON"
                                        outlined: true
                                        implicitHeight: Style.space(32)
                                        hPad: Style.space(16)
                                        foreground: root.fg
                                        accent: root.accent
                                        fontFamily: root.fontFamily
                                        pixelSize: root.fsSub
                                        onClicked: root.tm.exportData("json")
                                    }
                                }
                                Text {
                                    width: parent.width
                                    text: "Files go to ~/.local/share/omatravel/exports/. CSV opens in any spreadsheet."
                                    color: root.dim
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fsSub
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                }
                            }
                        }

                        // ---- settings ----
                        SettingsView {
                            anchors.fill: parent
                            visible: root.currentTab === "look"
                            store: root.tm ? root.tm.settings : null
                            readSetting: function(key, fallback) {
                                return root.hostWidget ? root.hostWidget.setting(key, fallback) : fallback
                            }
                            ink: root.fg
                            accent: root.accent
                            panelBg: root.panelBg
                            barFg: root.fg
                            fontFamily: root.fontFamily
                            popped: root.inWindow
                            footnote: !(root.tm && root.tm.activeTheme === "auto") ? ""
                                : (root.tm.systemTheme
                                    ? "Following your Omarchy theme"
                                      + (root.tm.systemTheme.name ? " \u201c" + root.tm.systemTheme.name + "\u201d" : "")
                                      + " \u2014 colours update the moment you switch it."
                                    : "Couldn't read an Omarchy theme from ~/.config/omarchy/current \u2014 using the shell's colours.  [" + root.tm.themeDebug + "]")
                        }

                        // ---- profiles ----
                        Flickable {
                            anchors.fill: parent
                            visible: root.currentTab === "profiles"
                            contentHeight: profCol.height + Style.space(40)
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: profCol
                                x: Style.space(16)
                                y: Style.space(14)
                                width: parent.width - Style.space(32)
                                spacing: Style.space(8)

                                SectionLabel {
                                    text: "New profile"
                                    foreground: root.fg
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsSub
                                }
                                RowLayout {
                                    width: parent.width
                                    spacing: Style.space(8)
                                    FieldBox {
                                        id: profileField
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Style.space(32)
                                        placeholderText: "Profile name"
                                        foreground: root.fg
                                        accent: root.accent
                                        fontFamily: root.fontFamily
                                        pixelSize: root.fsMain
                                        onTextChanged: root.newProfile = text
                                        onAccepted: { root.tm.createProfile(root.newProfile); profileField.clear() }
                                    }
                                    FlatButton {
                                        Layout.preferredHeight: Style.space(32)
                                        text: "Create"
                                        outlined: true
                                        selected: true
                                        hPad: Style.space(16)
                                        foreground: root.fg
                                        accent: root.accent
                                        fontFamily: root.fontFamily
                                        pixelSize: root.fsMain
                                        onClicked: { root.tm.createProfile(root.newProfile); profileField.clear() }
                                    }
                                }

                                Item { width: 1; height: Style.space(8) }
                                SectionLabel {
                                    text: "Your profiles"
                                    foreground: root.fg
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsSub
                                }
                                Repeater {
                                    model: root.tm ? root.tm.profileNames : []
                                    delegate: Rectangle {
                                        id: profRow
                                        required property string modelData
                                        readonly property bool active: profRow.modelData === root.tm.activeProfile
                                        width: profCol.width
                                        height: Style.space(52)
                                        radius: Style.space(10)
                                        color: profRow.active ? root.selectedFill : "transparent"
                                        border.width: 1
                                        border.color: profRow.active
                                            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6)
                                            : root.faint

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: root.gutter
                                            anchors.right: profActions.left
                                            anchors.rightMargin: Style.space(8)
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: profRow.modelData + (profRow.active ? "  ✓" : "")
                                            color: profRow.active ? root.accent : root.fg
                                            font.family: root.fontFamily
                                            font.pixelSize: root.fsMain
                                            font.bold: profRow.active
                                            elide: Text.ElideRight
                                            textFormat: Text.PlainText
                                        }
                                        Row {
                                            id: profActions
                                            anchors.right: parent.right
                                            anchors.rightMargin: Style.space(10)
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Style.space(6)
                                            FlatButton {
                                                visible: !profRow.active
                                                text: "Switch"
                                                outlined: true
                                                implicitHeight: Style.space(30)
                                                foreground: root.fg
                                                accent: root.accent
                                                fontFamily: root.fontFamily
                                                pixelSize: root.fsSub
                                                onClicked: root.tm.switchProfile(profRow.modelData)
                                            }
                                            FlatButton {
                                                visible: profRow.modelData !== "default"
                                                text: "✕"
                                                outlined: true
                                                implicitHeight: Style.space(30)
                                                hPad: Style.space(10)
                                                foreground: root.fg
                                                accent: root.accent
                                                fontFamily: root.fontFamily
                                                pixelSize: root.fsSub
                                                onClicked: root.tm.deleteProfile(profRow.modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---- add a place (bottom) ----
                    Item {
                        id: addPanel
                        visible: root.currentTab === "places" || root.currentTab === "wishlist"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: addCol.implicitHeight + Style.space(32)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 1
                            color: root.faint
                        }

                        ColumnLayout {
                            id: addCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: root.gutter
                            anchors.rightMargin: root.gutter
                            anchors.topMargin: root.gutter
                            spacing: Style.space(10)

                            SectionLabel {
                                text: "Add a place"
                                foreground: root.fg
                                fontFamily: root.fontFamily
                                pixelSize: root.fsSub
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.space(8)
                                FieldBox {
                                    id: countryField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Style.space(32)
                                    placeholderText: "Country"
                                    foreground: root.fg
                                    accent: root.accent
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsMain
                                    onTextChanged: root.newCountry = text
                                    onAccepted: root.doAddCountry()
                                }
                                FlatButton {
                                    Layout.preferredHeight: Style.space(32)
                                    text: "Add"
                                    outlined: true
                                    hPad: Style.space(18)
                                    foreground: root.fg
                                    accent: root.accent
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsMain
                                    onClicked: root.doAddCountry()
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: Style.space(6)
                                visible: suggestRepeater.count > 0
                                Repeater {
                                    id: suggestRepeater
                                    model: root.tm && root.newCountry.length > 0
                                        ? root.tm.countrySuggestions(root.newCountry) : []
                                    delegate: FlatButton {
                                        required property string modelData
                                        text: modelData
                                        outlined: true
                                        implicitHeight: Style.space(28)
                                        hPad: Style.space(12)
                                        foreground: root.fg
                                        accent: root.accent
                                        fontFamily: root.fontFamily
                                        pixelSize: root.fsSub
                                        onClicked: { countryField.text = modelData; root.doAddCountry() }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: Style.space(4)
                                text: root.newCityForCountry
                                      ? ("Adding to " + root.newCityForCountry)
                                      : "Pick a country above, or click a city on the globe."
                                color: root.newCityForCountry ? root.accent : root.dim
                                font.family: root.fontFamily
                                font.pixelSize: root.fsSub
                                font.bold: root.newCityForCountry !== ""
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.space(8)
                                FieldBox {
                                    id: cityField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Style.space(32)
                                    placeholderText: "City"
                                    foreground: root.fg
                                    accent: root.accent
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsMain
                                    onTextChanged: root.newCity = text
                                    onAccepted: root.doAddCity()
                                }
                                FieldBox {
                                    id: dateField
                                    Layout.preferredWidth: Style.space(132)
                                    Layout.preferredHeight: Style.space(32)
                                    visible: !root.addAsWishlist
                                    placeholderText: "YYYY-MM-DD"
                                    foreground: root.fg
                                    accent: root.accent
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsMain
                                    onTextChanged: root.newCityDate = text
                                    onAccepted: root.doAddCity()
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.space(8)
                                FlatButton {
                                    Layout.preferredHeight: Style.space(32)
                                    text: root.addAsWishlist ? "♡ Wishlist" : "✓ Visited"
                                    outlined: true
                                    selected: true
                                    hPad: Style.space(16)
                                    foreground: root.fg
                                    accent: root.addAsWishlist ? root.wishColor : root.accent
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsMain
                                    onClicked: root.addAsWishlist = !root.addAsWishlist
                                }
                                Item { Layout.fillWidth: true }
                                FlatButton {
                                    Layout.preferredHeight: Style.space(32)
                                    text: "Add city"
                                    outlined: true
                                    selected: true
                                    hPad: Style.space(20)
                                    foreground: root.fg
                                    accent: root.accent
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsMain
                                    onClicked: root.doAddCity()
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: !root.addAsWishlist
                                text: "A date (YYYY, YYYY-MM or YYYY-MM-DD) puts the city on your travel path. Been there again? Add the same city with a new date."
                                color: root.dim
                                font.family: root.fontFamily
                                font.pixelSize: root.fsSub
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                            }
                        }
                    }
                }

                // ---- controls overlay ----
                Rectangle {
                    anchors.fill: parent
                    visible: root.helpVisible
                    color: root.panelBg
                    z: 5

                    MouseArea { anchors.fill: parent }

                    Column {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - Style.space(48), Style.space(820))
                        spacing: Style.space(22)

                        Text {
                            text: "CONTROLS"
                            color: root.fg
                            font.family: root.fontFamily
                            font.pixelSize: root.fsMain + 6
                            font.bold: true
                            textFormat: Text.PlainText
                        }

                        Row {
                            id: helpCols
                            width: parent.width
                            spacing: Style.space(56)

                            Repeater {
                                model: root.controlSections
                                delegate: Column {
                                    id: helpSection
                                    required property var modelData
                                    width: (helpCols.width - helpCols.spacing) / 2

                                    Text {
                                        height: Style.space(34)
                                        verticalAlignment: Text.AlignVCenter
                                        text: helpSection.modelData.title
                                        color: root.dim
                                        font.family: root.fontFamily
                                        font.pixelSize: root.fsSub
                                        font.bold: true
                                        textFormat: Text.PlainText
                                    }
                                    Repeater {
                                        model: helpSection.modelData.controls
                                        delegate: Item {
                                            id: helpRow
                                            required property var modelData
                                            width: helpSection.width
                                            height: Style.space(40)
                                            Text {
                                                id: helpInput
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: Style.space(120)
                                                text: helpRow.modelData.input
                                                color: root.fg
                                                font.family: root.fontFamily
                                                font.pixelSize: root.fsSub
                                                font.bold: true
                                                elide: Text.ElideRight
                                                textFormat: Text.PlainText
                                            }
                                            Text {
                                                anchors.left: helpInput.right
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: helpRow.modelData.action
                                                color: root.dim
                                                font.family: root.fontFamily
                                                font.pixelSize: root.fsSub
                                                elide: Text.ElideRight
                                                textFormat: Text.PlainText
                                            }
                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.bottom: parent.bottom
                                                height: 1
                                                color: root.faint
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
