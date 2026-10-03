pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

// layout: header bar on top, big globe on the left,
// tabbed sidebar on the right with the "add a place" form docked at the bottom.
Panel {
    id: root
    moduleName: "io.github.qempexe.omatravel"
    manageIpc: false

    // injected by BarWidget
    property var anchorItem: null
    property var hostWidget: null
    property var travelModel: null

    property string currentTab: "places"
    property string query: ""
    property bool helpVisible: false
    property string newCountry: ""
    property string newCity: ""
    property string newCityDate: ""
    property string newCityForCountry: ""
    property bool addAsWishlist: false
    property string newProfile: ""

    // ── detach: the whole panel (`card`) can live in the bar popup or in its own window ──
    property bool detached: false
    // ── colours: ONE palette shared by the bar popup and the detached window ─────────
    //   named theme            -> that theme's colours
    //   "Follow Omarchy"       -> live Omarchy colours (colors.toml), re-read when the theme changes
    //   Omarchy file not found -> the shell's own bar colours (made opaque)
    // Nothing below depends on `detached`, so both variants always paint identically.
    readonly property bool useBarColors: !tm || (tm.activeTheme === "auto" && tm.systemTheme === null)
    readonly property bool followSystem: !!tm && tm.activeTheme === "auto" && tm.systemTheme !== null
    readonly property color fg: useBarColors && root.barForeground !== undefined
        ? root.barForeground : (tm ? tm.themeText : "#e8dcc8")
    readonly property color panelBg: {
        if (useBarColors && root.barBackground !== undefined) {
            var c = root.barBackground
            return Qt.rgba(c.r, c.g, c.b, 1)          // bar colours may be translucent; the panel never is
        }
        return tm ? tm.themeBackground : Qt.rgba(0.10, 0.09, 0.08, 1)
    }
    // Tell the model what colour the shell is using, so it can tell which Omarchy theme is active.
    Binding { target: root.tm; property: "shellBg"; value: root.barBackground; when: !!root.tm }

    property var _home: null          // the popup's content item, remembered while detached

    readonly property var tm: travelModel
    readonly property color accent: tm ? tm.themeAccent : "#d4a35a"
    readonly property color wishColor: "#cba6f7"
    // One consistent, compact type scale (derived from the shell body size).
    readonly property int fsMain: Math.max(10, Math.round(Style.font.body * 0.9))
    readonly property int fsSub:  Math.max(9,  Math.round(Style.font.body * 0.8))

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
            { input: "+ / − / ⌖", action: "Zoom in, out, recentre" }
        ] },
        { title: "PLACES", controls: [
            { input: "CLICK COUNTRY", action: "Select it and show its cities" },
            { input: "CLICK CITY CHIP", action: "Fly to it on the globe" },
            { input: "DATE", action: "YYYY, YYYY-MM or YYYY-MM-DD adds it to the path" },
            { input: "SEARCH", action: "Filter your countries and cities" },
            { input: "ESC", action: "Close" }
        ] }
    ]

    onOpenedChanged: if (opened && tm) tm.ensureIndex()

    function detach() {
        if (root.detached) return
        if (tm) tm.ensureIndex()
        detachLoader.active = true                 // DetachedWindow calls _enterWindow() once it exists
    }

    function _enterWindow(win) {
        if (root.detached || !win) return
        root._home = card.parent
        card.parent = win.contentItem
        root.detached = true
        root.helpVisible = false
        root.controller.hide()                     // close the bar popup
    }

    // Window -> bar. `show` re-opens the popup; false just closes everything.
    function _dock(show) {
        if (!root.detached) return
        if (root._home) card.parent = root._home
        root.detached = false
        detachLoader.active = false                // destroys the window
        if (show) root.controller.show()
    }
    function reattach() { _dock(true) }

    function open()  { root.controller.show() }
    function close() { root.controller.hide() }
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
            color: root.panelBg
            implicitWidth: Style.space(1180)
            implicitHeight: Style.space(760)
            onClosedByUser: root._dock(false)
            Component.onCompleted: root._enterWindow(dwin)
        }
    }

    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(1180))
        contentHeight: panel.fittedContentHeight(Style.space(760))

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

            Rectangle {                      // same opaque background in the popup and the window
                anchors.fill: parent
                z: -1
                radius: root.detached ? 0 : Style.radius.small
                color: root.panelBg
            }

            // ══ HEADER ═════════════════════════════════════════════════
            Item {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Style.space(68)
                z: 2

                Text {
                    id: title
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space(20)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "OMATRAVEL"
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: root.fsMain + 6
                    font.bold: true
                    font.letterSpacing: 1
                    textFormat: Text.PlainText
                }

                FlatButton {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.rightMargin: Style.space(14)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    hPad: Style.space(10)
                    foreground: root.fg
                    accent: root.accent
                    fontFamily: root.fontFamily
                    pixelSize: root.fsMain
                    onClicked: root.detached ? root._dock(false) : root.close()
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
                    text: root.detached ? "↙" : "↗"
                    hPad: Style.space(10)
                    foreground: root.fg
                    accent: root.accent
                    fontFamily: root.fontFamily
                    pixelSize: root.fsMain + 2
                    onClicked: root.detached ? root._dock(true) : root.detach()
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

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: root.faint
                }
            }

            // ══ BODY ═══════════════════════════════════════════════════
            Item {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.bottom: parent.bottom
                z: 2

                readonly property real sidebarWidth: Math.min(Style.space(440), width * 0.42)

                // ── map pane ───────────────────────────────────────────
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
                        anchors.leftMargin: Style.space(16)
                        anchors.rightMargin: Style.space(16)
                        anchors.topMargin: Style.space(16)
                        active: root.opened || root.detached
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
                            anchors.leftMargin: Style.space(20)
                            anchors.right: stats.left
                            anchors.rightMargin: Style.space(12)
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.tm && root.tm.notice !== ""
                                  ? root.tm.notice
                                  : "Drag to spin  ·  scroll to zoom  ·  click a city"
                            color: root.tm && root.tm.notice !== "" ? root.accent : root.dim
                            font.family: root.fontFamily
                            font.pixelSize: root.fsSub
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                        Text {
                            id: stats
                            anchors.right: parent.right
                            anchors.rightMargin: Style.space(20)
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

                // ── sidebar ────────────────────────────────────────────
                Item {
                    id: sidebar
                    width: body.sidebarWidth
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    readonly property bool narrow: width < Style.space(340)

                    // tabs ─ four equal outlined pills
                    Item {
                        id: tabs
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: Style.space(60)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.space(14)
                            anchors.rightMargin: Style.space(14)
                            anchors.topMargin: Style.space(12)
                            anchors.bottomMargin: Style.space(12)
                            spacing: Style.space(6)

                            Repeater {
                                model: [
                                    { key: "places",   label: "Places" },
                                    { key: "wishlist", label: "Wishlist" },
                                    { key: "look",     label: "Look" },
                                    { key: "profiles", label: "Profiles" }
                                ]
                                delegate: FlatButton {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    hPad: Style.space(4)
                                    outlined: true
                                    text: modelData.label
                                    selected: root.currentTab === modelData.key
                                    foreground: root.fg
                                    accent: root.accent
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsSub
                                    onClicked: root.currentTab = modelData.key
                                }
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: root.faint
                        }
                    }

                    // tab content
                    Item {
                        id: content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: tabs.bottom
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: addPanel.visible ? addPanel.height : 0
                        clip: true

                        // ══ PLACES ════════════════════════════════════
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

                                        // Dated visits, one line per city, each removable on its own.
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

                        // ══ WISHLIST ══════════════════════════════════
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

                        // ══ LOOK ══════════════════════════════════════
                        Flickable {
                            anchors.fill: parent
                            visible: root.currentTab === "look"
                            contentHeight: lookCol.height + Style.space(40)
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: lookCol
                                x: Style.space(16)
                                y: Style.space(14)
                                width: parent.width - Style.space(32)
                                spacing: Style.space(8)

                                SectionLabel {
                                    text: "Theme"
                                    foreground: root.fg
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsSub
                                }
                                Flow {
                                    width: parent.width
                                    spacing: Style.space(6)
                                    Repeater {
                                        model: root.tm ? ["auto"].concat(root.tm.themeNames) : []
                                        delegate: FlatButton {
                                            id: themeBtn
                                            required property string modelData
                                            text: themeBtn.modelData === "auto" ? "Follow Omarchy" : themeBtn.modelData
                                            outlined: true
                                            selected: themeBtn.modelData === root.tm.activeTheme
                                            dotColor: root.tm.themeColor(themeBtn.modelData)
                                            implicitHeight: Style.space(32)
                                            foreground: root.fg
                                            accent: root.accent
                                            fontFamily: root.fontFamily
                                            pixelSize: root.fsSub
                                            onClicked: root.tm.setTheme(themeBtn.modelData)
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    visible: root.tm && root.tm.activeTheme === "auto"
                                    text: root.tm && root.tm.systemTheme
                                          ? "Following your Omarchy theme"
                                            + (root.tm.systemTheme.name ? " “" + root.tm.systemTheme.name + "”" : "")
                                            + " — colours update the moment you switch it."
                                          : "Couldn't read an Omarchy theme from ~/.config/omarchy/current — using the shell's colours.  [" + root.tm.themeDebug + "]"
                                    color: root.dim
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fsSub
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                }

                                Item { width: 1; height: Style.space(8) }
                                SectionLabel {
                                    text: "Bar icon"
                                    foreground: root.fg
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsSub
                                }
                                FieldBox {
                                    id: iconField
                                    width: parent.width
                                    height: Style.space(32)
                                    placeholderText: "🌍"
                                    foreground: root.fg
                                    accent: root.accent
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsMain
                                    Component.onCompleted: text = root.tm ? root.tm.display.icon : ""
                                    onAccepted: root.tm.setIcon(text)
                                    onFocusedChanged: if (!focused && root.tm) root.tm.setIcon(text)
                                }

                                Item { width: 1; height: Style.space(8) }
                                SectionLabel {
                                    text: "Display"
                                    foreground: root.fg
                                    fontFamily: root.fontFamily
                                    pixelSize: root.fsSub
                                }
                                Repeater {
                                    model: [
                                        { key: "showFlags",  label: "Show flags" },
                                        { key: "showPath",   label: "Travel path on globe" },
                                        { key: "showPlaces", label: "City labels on globe" }
                                    ]
                                    delegate: Item {
                                        id: toggleRow
                                        required property var modelData
                                        width: lookCol.width
                                        height: Style.space(44)
                                        Text {
                                            anchors.left: parent.left
                                            anchors.right: toggleBtn.left
                                            anchors.rightMargin: Style.space(8)
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: toggleRow.modelData.label
                                            color: root.fg
                                            font.family: root.fontFamily
                                            font.pixelSize: root.fsMain
                                            elide: Text.ElideRight
                                            textFormat: Text.PlainText
                                        }
                                        FlatButton {
                                            id: toggleBtn
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: Style.space(64)
                                            outlined: true
                                            text: root.tm.display[toggleRow.modelData.key] ? "On" : "Off"
                                            selected: root.tm.display[toggleRow.modelData.key]
                                            foreground: root.fg
                                            accent: root.accent
                                            fontFamily: root.fontFamily
                                            pixelSize: root.fsSub
                                            onClicked: root.tm.setDisplayFlag(toggleRow.modelData.key,
                                                                              !root.tm.display[toggleRow.modelData.key])
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

                        // ══ PROFILES ══════════════════════════════════
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
                                            anchors.leftMargin: Style.space(16)
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

                    // ══ ADD A PLACE (docked at the bottom) ═══════════════
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
                            anchors.leftMargin: Style.space(16)
                            anchors.rightMargin: Style.space(16)
                            anchors.topMargin: Style.space(16)
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

                // ══ CONTROLS OVERLAY ══════════════════════════════════
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
