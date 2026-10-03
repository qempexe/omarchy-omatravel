import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// State + persistence for Omatravel. Holds the store (profiles, theme, display),
// lazily loads the city lookup index and the zoom-band layers, and derives the
// data the bar button, the panel and the globe bind to.
Item {
    id: root

    // ── locations (relative to the plugin, so any install path works) ─────────
    readonly property string pluginDir: decodeURIComponent(
        Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")).replace(/\/$/, "")
    // Read-only atlas data ships inside the plugin folder...
    readonly property string layerDir:  pluginDir + "/data/layers"
    // ...but the user's own data lives OUTSIDE it: Quickshell hot-reloads the whole shell
    // whenever a file in a watched config/plugin folder changes, so saving into the plugin
    // folder made every edit restart the bar.
    readonly property string dataDir:  (Quickshell.env("XDG_DATA_HOME")
                                        || (Quickshell.env("HOME") + "/.local/share")) + "/omatravel"
    readonly property string legacyStorePath: pluginDir + "/data/travel-data.json"
    readonly property string storePath: dataDir + "/travel-data.json"
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    property bool storeReady: false

    // ── state ─────────────────────────────────────────────────────────────────
    property var store: Model.parseStore("")
    property var layerIndex: ({})
    property bool indexWanted: false
    property bool indexReady: false
    property var wantedBands: ({})
    property var bands: ({})
    property string notice: ""
    property var shellBg: null              // current shell bar colour (set by Panel)
    property string themeDebug: "reader has not run yet"
    property var systemTheme: null          // live Omarchy colours, or null if unavailable
    property string _lastText: ""

    // ── derived ───────────────────────────────────────────────────────────────
    readonly property int    countryCount: Model.countryCount(store)
    readonly property int    cityCount:    Model.cityCount(store)
    readonly property var    countries:    _countryRows()
    readonly property var    wishlist:     Model.wishlistRows(store)
    readonly property var    profileNames: Model.profileNames(store)
    readonly property string activeProfile: store.activeProfile
    readonly property string activeTheme:   store.theme
    readonly property var    themeNames:    Model.themeNames()
    readonly property color  themeAccent:     Model.themeFor(store, systemTheme).accent
    readonly property color  themeText:       Model.themeFor(store, systemTheme).text
    readonly property color  themeBackground: Model.themeFor(store, systemTheme).background
    readonly property var    display:      Model.display(store)
    readonly property string displayIcon:  Model.display(store).icon
    readonly property var    globePoints:  _buildGlobePoints()
    readonly property var    pathPoints:   _buildPath(globePoints)

    function themeColor(name) { return Model.themeColor(name, systemTheme) }
    function countrySuggestions(prefix) { return Model.countrySuggestions(prefix, 6) }
    function canonicalCountry(name) { return Model.canonicalCountry(name) }
    function countryNameForCode(cc) { return Model.countryName(cc) }

    // ── lazy data ─────────────────────────────────────────────────────────────
    function ensureIndex() { if (!indexWanted) indexWanted = true }

    function requestBand(name) {
        if (wantedBands[name]) return
        var w = {}
        for (var k in wantedBands) w[k] = wantedBands[k]
        w[name] = true
        wantedBands = w
    }

    function _bandLoaded(name, text) {
        var d = null
        try { d = JSON.parse(text) } catch (e) { d = null }
        if (!d || !d.lng) return
        var b = {}
        for (var k in bands) b[k] = bands[k]
        b[name] = d
        bands = b
    }

    function _lookup(city, country) {
        var keys = Model.indexKeys(city, country)
        for (var i = 0; i < keys.length; i++)
            if (layerIndex[keys[i]]) return layerIndex[keys[i]]
        return null
    }

    // ── persistence ───────────────────────────────────────────────────────────
    function _commit(mutator) {
        var clone = Model.sanitize(JSON.parse(JSON.stringify(root.store)))
        mutator(clone)
        root.store = clone
        _write(clone)
    }

    function _write(obj) {
        var text = JSON.stringify(obj, null, 2)
        root._lastText = text
        if (typeof storeFile.setText === "function") {
            storeFile.setText(text)
        } else {                                    // very old Quickshell
            fallbackWriter.command = ["sh", "-c",
                "mkdir -p \"$1\" && printf %s \"$2\" > \"$3\"", "sh", root.dataDir, text, root.storePath]
            fallbackWriter.running = false
            fallbackWriter.running = true
        }
    }

    function _say(msg) { notice = msg; noticeTimer.restart() }

    // ── places ────────────────────────────────────────────────────────────────
    function addCountry(name) {
        name = Model.canonicalCountry(name)
        if (!name) return
        if (!Model.countryCode(name))
            _say("“" + name + "” isn't a country I know — saved anyway (no flag).")
        _commit(function(s) {
            var p = s.profiles[s.activeProfile]
            if (!p.countries[name]) p.countries[name] = { cities: [], city_meta: {} }
        })
    }

    function removeCountry(name) {
        _commit(function(s) { delete s.profiles[s.activeProfile].countries[name] })
    }

    function addCity(country, city, date) {
        country = Model.canonicalCountry(country)
        city = String(city || "").trim()
        if (!country || !city) { _say("Pick a country (＋) and type a city."); return false }
        var nd = Model.normalizeDate(date)
        if (nd === null) { _say("Date must look like 2019, 2019-05 or 2019-05-02."); return false }
        ensureIndex()
        var have = Model.activeProfile(store).countries[country]
        var known = have && have.cities.indexOf(city) !== -1
        if (known) {
            var prior = Model.visitsOf(have.city_meta[city])
            if (!nd) { _say(city + " is already in your list — add a date to log another visit."); return false }
            if (prior.indexOf(nd) !== -1) { _say("That visit to " + city + " is already logged."); return false }
            _say("Visit " + (prior.length + 1) + " logged for " + city + ".")
        }
        _commit(function(s) {
            var p = s.profiles[s.activeProfile]
            if (!p.countries[country]) p.countries[country] = { cities: [], city_meta: {} }
            var cd = p.countries[country]
            if (cd.cities.indexOf(city) === -1) cd.cities.push(city)
            if (nd) {
                var meta = cd.city_meta[city] || (cd.city_meta[city] = {})
                var v = Model.visitsOf(meta)
                v.push(nd)
                meta.visits = v
                Model.sanitize(s)                  // re-sorts and de-duplicates the visits
            }
        })
        return true
    }

    function removeCity(country, city) {
        _commit(function(s) {
            var cd = s.profiles[s.activeProfile].countries[country]
            if (!cd) return
            cd.cities = cd.cities.filter(function(c) { return c !== city })
            delete cd.city_meta[city]
        })
    }

    // Remove a single dated visit; the city itself stays on the list.
    function removeVisit(country, city, date) {
        _commit(function(s) {
            var cd = s.profiles[s.activeProfile].countries[country]
            if (!cd || !cd.city_meta[city]) return
            cd.city_meta[city].visits = Model.visitsOf(cd.city_meta[city])
                .filter(function(d) { return d !== date })
            Model.sanitize(s)
        })
    }

    function addWishlist(country, city) {
        country = Model.canonicalCountry(country)
        city = String(city || "").trim()
        if (!country || !city) { _say("Pick a country (＋) and type a city."); return false }
        ensureIndex()
        _commit(function(s) {
            var p = s.profiles[s.activeProfile]
            if (!p.wishlist[country]) p.wishlist[country] = []
            if (p.wishlist[country].indexOf(city) === -1) p.wishlist[country].push(city)
        })
        return true
    }

    function removeWishlist(country, city) {
        _commit(function(s) {
            var wl = s.profiles[s.activeProfile].wishlist
            if (!wl[country]) return
            wl[country] = wl[country].filter(function(c) { return c !== city })
            if (wl[country].length === 0) delete wl[country]
        })
    }

    // ── profiles / look ───────────────────────────────────────────────────────
    function createProfile(name) {
        name = String(name || "").trim()
        if (!name) return
        _commit(function(s) {
            if (!s.profiles[name]) s.profiles[name] = { countries: {}, wishlist: {} }
            s.activeProfile = name
        })
    }

    function deleteProfile(name) {
        if (name === "default") { _say("The default profile can't be deleted."); return }
        _commit(function(s) {
            delete s.profiles[name]
            if (s.activeProfile === name) s.activeProfile = "default"
        })
    }

    function switchProfile(name) {
        _commit(function(s) { if (s.profiles[name]) s.activeProfile = name })
    }

    function setTheme(name) { _commit(function(s) { s.theme = name }) }

    function setIcon(icon) {
        _commit(function(s) { s.display.icon = Model.plain(String(icon || "").trim().slice(0, 8)) || "🌍" })
    }

    function setShowFlags(on) { setDisplayFlag("showFlags", on) }

    function setDisplayFlag(key, on) {
        if (["showFlags", "showPath", "showPlaces"].indexOf(key) === -1) return
        _commit(function(s) { s.display[key] = !!on })
    }

    // Map position of one of the user's cities, or null if it has no pin.
    function pointFor(country, city) {
        var pts = globePoints
        for (var i = 0; i < pts.length; i++)
            if (pts[i].country === country && pts[i].name === city) return pts[i]
        return null
    }

    // Multi-line tooltip for the bar button.
    function tooltipText() {
        var d = display, rows = countries
        var lines = ["Omatravel"]
        for (var i = 0; i < rows.length && i < d.maxTooltipCountries; i++) {
            var r = rows[i], cs = r.cities.slice(0, d.maxTooltipCities).join(", ")
            if (r.cities.length > d.maxTooltipCities) cs += ", …"
            lines.push((d.showFlags ? r.flag + " " : "") + r.name + (cs ? ": " + cs : ""))
        }
        if (rows.length > d.maxTooltipCountries)
            lines.push("+ " + (rows.length - d.maxTooltipCountries) + " more")
        return lines.map(function(l) { return Model.plain(l) }).join("\n")
    }

    function setTooltipLimits(cMax, cityMax) {
        _commit(function(s) {
            s.display.maxTooltipCountries = Math.max(1, parseInt(cMax) || 8)
            s.display.maxTooltipCities = Math.max(1, parseInt(cityMax) || 10)
        })
    }

    // ── derived data ──────────────────────────────────────────────────────────
    function _countryRows() {
        var rows = Model.countryRows(store)
        for (var i = 0; i < rows.length; i++) {
            var r = rows[i], cs = []
            for (var j = 0; j < r.cities.length; j++)
                cs.push({ name: r.cities[j],
                          visits: Model.visitsOf((store.profiles[store.activeProfile].countries[r.name].city_meta || {})[r.cities[j]]),
                          pinned: !indexReady || _lookup(r.cities[j], r.name) !== null })
            r.cityItems = cs
        }
        return rows
    }

    function _buildGlobePoints() {
        var out = [], p = Model.activeProfile(store)
        var cs = p.countries
        for (var country in cs) {
            var cd = cs[country]
            for (var i = 0; i < cd.cities.length; i++) {
                var city = cd.cities[i], meta = cd.city_meta[city] || {}
                var hit = (meta.lat !== undefined && meta.lng !== undefined)
                          ? [meta.lat, meta.lng] : _lookup(city, country)
                if (!hit) continue
                var visits = Model.visitsOf(meta)
                out.push({ lat: hit[0], lng: hit[1], name: city, country: country,
                           kind: "visited", visits: visits, visitCount: Math.max(1, visits.length),
                           date: visits.length ? visits[visits.length - 1] : "" })
            }
        }
        var wl = p.wishlist
        for (var wc in wl) {
            for (var j = 0; j < wl[wc].length; j++) {
                var wh = _lookup(wl[wc][j], wc)
                if (wh) out.push({ lat: wh[0], lng: wh[1], name: wl[wc][j], country: wc,
                                   kind: "wishlist", visits: [], visitCount: 0, date: "" })
            }
        }
        return out
    }

    // Every dated visit in chronological order (stable for equal dates), so a city
    // visited twice appears twice and the path can return to it.
    function _buildPath(points) {
        var dated = [], n = 0
        for (var i = 0; i < points.length; i++) {
            var pt = points[i]
            if (pt.kind !== "visited") continue
            for (var j = 0; j < pt.visits.length; j++) {
                var v = pt.visits[j]
                dated.push({ pt: { lat: pt.lat, lng: pt.lng, name: pt.name, country: pt.country,
                                   kind: "visited", date: v, visits: pt.visits, visitCount: pt.visitCount },
                             key: Model.dateKey(v), n: n++ })
            }
        }
        dated.sort(function(a, b) { return a.key < b.key ? -1 : a.key > b.key ? 1 : a.n - b.n })
        return dated.map(function(d) { return d.pt })
    }

    // ── files ─────────────────────────────────────────────────────────────────
    FileView {
        id: storeFile
        path: root.storeReady ? root.storePath : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            var t = storeFile.text()
            if (t === root._lastText) return
            root._lastText = t
            root.store = Model.parseStore(t)
        }
        onLoadFailed: root._write(root.store)      // first run: create the file
    }

    // ── live Omarchy theme ─────────────────────────────────────────────────────
    // `omarchy-theme-set` deletes and recreates current/theme/, which silently kills any inotify
    // watch on files inside it. So the colours are re-read with a short-lived `cat` instead:
    // on start, whenever theme.name changes (that file survives), shortly after (the swap may
    // still be in flight), on switching to "Follow Omarchy", and on a slow poll while following (the shell recolouring also triggers a re-read).
    readonly property string omarchyDir: configHome + "/omarchy/current"
    function _h2(v) { return ("0" + Math.round(v * 255).toString(16)).slice(-2) }
    function refreshSystemTheme() { if (!themeReader.running) themeReader.running = true }

    // Dumps the active theme's files (current/theme, falling back to the named theme's folder).
    Process {
        id: themeReader
        command: ["sh", "-c", [
            'd="$1"; cfg="$2"',
            'data="${XDG_DATA_HOME:-$HOME/.local/share}"; state="${XDG_STATE_HOME:-$HOME/.local/state}"',
            '# 1. find the folder that holds the active theme (layout differs between Omarchy versions)',
            'cur=""',
            'for c in "$d" "$HOME/.config/omarchy/current" "$state/omarchy/current" "$data/omarchy/current" "$state/omarchy" "$data/omarchy"; do',
            '  if [ -r "$c/theme.name" ] || [ -d "$c/theme" ]; then cur="$c"; break; fi',
            'done',
            '# 2. the active theme name: file first, then the omarchy CLI',
            'n=""',
            '[ -n "$cur" ] && n=$(cat "$cur/theme.name" 2>/dev/null | tr -d "\\r\\n")',
            '[ -z "$n" ] && n=$(omarchy-theme-current 2>/dev/null || "$data/omarchy/bin/omarchy-theme-current" 2>/dev/null)',
            '[ -z "$n" ] && [ -n "$cur" ] && [ -L "$cur/theme" ] && n=$(basename "$(readlink -f "$cur/theme")")',
            'n=$(printf %s "$n" | tr "A-Z " "a-z-")',
            'echo "@@NAME $n"',
            '# 3. dump that theme\'s files',
            'found=0',
            'for t in "$cur/theme" "$cfg/omarchy/themes/$n" "$data/omarchy/themes/$n" "/usr/share/omarchy/themes/$n"; do',
            '  [ -d "$t" ] || continue',
            '  for f in colors.toml alacritty.toml kitty.conf waybar.css btop.theme mako.ini hyprland.conf; do',
            '    if [ -r "$t/$f" ]; then echo "@@FILE $f"; cat "$t/$f"; echo; found=1; fi',
            '  done',
            '  [ "$found" = 1 ] && break',
            'done',
            '# 3b. no "current" marker anywhere: dump every installed theme; QML picks the one matching the shell',
            'if [ "$found" = 0 ]; then',
            '  for t in "$cfg"/omarchy/themes/* "$data"/omarchy/themes/*; do',
            '    [ -d "$t" ] || continue',
            '    for f in colors.toml alacritty.toml kitty.conf; do',
            '      if [ -r "$t/$f" ]; then echo "@@THEME $(basename "$t")"; echo "@@FILE $f"; cat "$t/$f"; echo; found=2; break; fi',
            '    done',
            '  done',
            'fi',
            '# 4. nothing found: say what is there so it can be fixed',
            'if [ "$found" = 0 ]; then',
            '  echo "@@DIAG home=$HOME cfg=$cfg cur=$cur"',
            '  echo "@@DIAG ls-omarchy: $(ls "$cfg/omarchy" 2>&1 | tr "\\n" " ")"',
            '  echo "@@DIAG found: $(find "$HOME/.config/omarchy" "$HOME/.local/share/omarchy" "$HOME/.local/state/omarchy" -maxdepth 4 -name theme.name 2>/dev/null | head -3 | tr "\\n" " ")"',
            'fi',
            'exit 0'].join("\n"),
            "sh", root.omarchyDir, root.configHome]
        onExited: function(code) { if (code !== 0) root.themeDebug = "reader exited with code " + code }
        stdout: StdioCollector {
            onStreamFinished: {
                root.themeDebug = text.length
                    ? text.slice(0, 200).replace(/\n+/g, " | ")
                    : "reader returned nothing (dir: " + root.omarchyDir + ")"
                var t = null
                if (text.indexOf("@@THEME") >= 0) {
                    // No "current theme" marker: choose the installed theme that matches the shell's colours.
                    var list = Model.parseOmarchyThemes(text), c = root.shellBg
                    if (!c) {
                        root.themeDebug = "scanned " + list.length + " themes, waiting for the shell's colours"
                    } else {
                        var hex = "#" + root._h2(c.r) + root._h2(c.g) + root._h2(c.b)
                        var best = Model.closestTheme(list, hex)
                        if (best && best.dist < 0.012) t = best.theme
                        root.themeDebug = best
                            ? "scanned " + list.length + " themes; shell bg " + hex + ", closest " + best.theme.name
                              + " " + best.theme.background + (t ? " (matched)" : " (too different)")
                            : "no readable themes in " + root.configHome + "/omarchy/themes"
                    }
                } else {
                    t = Model.parseOmarchyTheme(text)
                }
                if (JSON.stringify(t) !== JSON.stringify(root.systemTheme)) root.systemTheme = t
            }
        }
    }
    FileView {
        id: omarchyName
        path: root.omarchyDir + "/theme.name"
        watchChanges: true
        onFileChanged: { reload(); root.refreshSystemTheme(); settleTimer.restart() }
    }
    onShellBgChanged: refreshSystemTheme()      // the shell recolours itself when the Omarchy theme changes
    Timer { id: settleTimer; interval: 500; onTriggered: root.refreshSystemTheme() }
    Timer {
        interval: 5000
        repeat: true
        running: root.store.theme === "auto"
        onTriggered: root.refreshSystemTheme()
    }
    Component.onCompleted: refreshSystemTheme()
    onActiveThemeChanged: if (activeTheme === "auto") refreshSystemTheme()

    FileView {
        id: indexFile
        path: root.indexWanted ? root.layerDir + "/index.json" : ""
        onLoaded: {
            try { root.layerIndex = JSON.parse(indexFile.text()) }
            catch (e) { root.layerIndex = ({}) }
            root.indexReady = true
        }
        onLoadFailed: root.indexReady = true
    }

    component BandLoader: FileView {
        required property string band
        property bool wanted: false
        property string dir: ""
        signal bandLoaded(string band, string text)
        path: wanted ? dir + "/" + band + ".json" : ""
        onLoaded: bandLoaded(band, text())
    }
    BandLoader { band: "z0"; wanted: root.wantedBands.z0 === true; dir: root.layerDir
                 onBandLoaded: function(b, t) { root._bandLoaded(b, t) } }
    BandLoader { band: "z1"; wanted: root.wantedBands.z1 === true; dir: root.layerDir
                 onBandLoaded: function(b, t) { root._bandLoaded(b, t) } }
    BandLoader { band: "z2"; wanted: root.wantedBands.z2 === true; dir: root.layerDir
                 onBandLoaded: function(b, t) { root._bandLoaded(b, t) } }
    BandLoader { band: "z3"; wanted: root.wantedBands.z3 === true; dir: root.layerDir
                 onBandLoaded: function(b, t) { root._bandLoaded(b, t) } }

    // Create the data dir and, once, copy an old in-plugin save across; only then open the store.
    Process {
        id: ensureDir
        command: ["sh", "-c",
            "mkdir -p \"$1\" && { [ -f \"$2\" ] || { [ -f \"$3\" ] && cp \"$3\" \"$2\"; }; }; true",
            "sh", root.dataDir, root.storePath, root.legacyStorePath]
        running: true
        onExited: root.storeReady = true
    }
    Process { id: fallbackWriter }
    Timer { id: noticeTimer; interval: 6000; onTriggered: root.notice = "" }
}
