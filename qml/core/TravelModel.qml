import QtQuick
import Quickshell
import Quickshell.Io
import "../js/Model.js" as Model

// state + saving for omatravel: profiles and places. theme and display options come from
// the settings store. loads the city index and the zoom layers lazily, and builds what
// the bar button, the panel and the globe show
Item {
    id: root

    // paths, relative to the plugin so any install path works
    readonly property string pluginDir: decodeURIComponent(
        Qt.resolvedUrl("../..").toString().replace(/^file:\/\//, "")).replace(/\/$/, "")
    // atlas data ships inside the plugin...
    readonly property string layerDir:  pluginDir + "/data/layers"
    // ...but your own data lives outside it. quickshell reloads the whole shell when a file
    // in a plugin folder changes, so saving in here restarted the bar on every edit
    readonly property string dataDir:  (Quickshell.env("XDG_DATA_HOME")
                                        || (Quickshell.env("HOME") + "/.local/share")) + "/omatravel"
    readonly property string legacyStorePath: pluginDir + "/data/travel-data.json"
    readonly property string storePath: dataDir + "/travel-data.json"
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    property bool storeReady: false

    // settings: panel edits win, then the shell's setting() (fallbacks), then the default
    property var settings: null
    property var fallbacks: ({})
    function opt(key, dflt) {
        var o = settings ? settings.values[key] : undefined
        if (o !== undefined) return o
        var f = fallbacks[key]
        return f !== undefined ? f : dflt
    }
    function clampInt(x, lo, hi, dflt) {
        var n = Math.round(Number(x))
        return isFinite(n) ? Math.max(lo, Math.min(hi, n)) : dflt
    }

    // state
    property var store: Model.parseStore("")
    property var layerIndex: ({})
    property bool indexWanted: false
    property bool indexReady: false
    property var wantedBands: ({})
    property var bands: ({})
    property string notice: ""
    property var shellBg: null              // current bar color (set by Panel)
    property string themeDebug: "reader has not run yet"
    property var systemTheme: null          // live omarchy colors, null if not available
    property string _lastText: ""
    property int viewYear: 0                // 0 = all trips, else the map as it was at the end of that year

    // derived
    readonly property int    countryCount: Model.countryCount(store)
    readonly property int    cityCount:    Model.cityCount(store)
    readonly property var    countries:    _countryRows()
    readonly property var    wishlist:     Model.wishlistRows(store)
    readonly property var    profileNames: Model.profileNames(store)
    readonly property string activeProfile: store.activeProfile
    readonly property bool   customTheme:   String(opt("theme", "auto")) === "custom"
    readonly property string activeTheme:   customTheme ? "custom"
                                            : (Model.themeNames().indexOf(String(opt("theme", "auto"))) !== -1
                                               ? String(opt("theme", "auto")) : "auto")
    readonly property var    themeNames:    Model.themeNames()
    function hexOr(v, dflt) {
        var t = String(v === undefined || v === null ? "" : v).trim()
        return /^#[0-9a-fA-F]{6}$/.test(t) ? t : dflt
    }
    readonly property var    _theme: customTheme
        ? { text: hexOr(opt("customFg", "#c0caf5"), "#c0caf5"),
            background: hexOr(opt("customBg", "#1a1b26"), "#1a1b26"),
            accent: hexOr(opt("accentColor", "#7aa2f7"), "#7aa2f7") }
        : Model.themeFor({ theme: activeTheme }, systemTheme)
    readonly property color  themeAccent:     _theme.accent
    readonly property color  themeText:       _theme.text
    readonly property color  themeBackground: _theme.background
    // look and window options (settings > look / window)
    readonly property var    look: ({
        opacity: clampInt(opt("opacity", 100), 50, 100, 100),
        cornerRadius: clampInt(opt("cornerRadius", 12), 0, 24, 12),
        outline: opt("outline", false) === true || opt("outline", false) === "true",
        surfaceTint: clampInt(opt("surfaceTint", 0), 0, 30, 0),
        fontScale: clampInt(opt("fontScale", 100), 80, 150, 100),
        density: ["compact", "comfortable", "spacious"].indexOf(String(opt("density", "comfortable"))) !== -1
                 ? String(opt("density", "comfortable")) : "comfortable",
        openAs: String(opt("openAs", "panel")) === "window" ? "window" : "panel",
        windowWidth: clampInt(opt("windowWidth", 1180), 800, 1800, 1180),
        windowHeight: clampInt(opt("windowHeight", 760), 500, 1200, 760)
    })
    readonly property var    display: ({
        icon: Model.plain(String(opt("icon", "\ud83c\udf0d")).trim().slice(0, 8)) || "\ud83c\udf0d",
        showCounts: opt("showCounts", true) !== false,
        showFlags: opt("showFlags", true) !== false,
        showPath: opt("showPath", true) !== false,
        showPlaces: opt("showPlaces", true) !== false,
        maxTooltipCountries: clampInt(opt("maxTooltipCountries", 8), 1, 30, 8),
        maxTooltipCities: clampInt(opt("maxTooltipCities", 10), 1, 30, 10)
    })
    readonly property string displayIcon:  display.icon
    readonly property var    allPoints:    _buildGlobePoints()
    readonly property var    globePoints:  Model.filterByYear(allPoints, viewYear)
    readonly property var    pathPoints:   _buildPath(globePoints)
    readonly property var    years:        Model.visitYears(store)
    readonly property var    stats:        Model.computeStats(store, _buildPath(allPoints))

    function themeColor(name) { return Model.themeColor(name, systemTheme) }
    function countrySuggestions(prefix) { return Model.countrySuggestions(prefix, 6) }
    function canonicalCountry(name) { return Model.canonicalCountry(name) }
    function countryNameForCode(cc) { return Model.countryName(cc) }

    // lazy data
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

    // private writes
    // travel history never goes on a command line (anyone local can read argv in /proc).
    // content goes in on stdin, argv only has the dir and file. owner-only temp file next to
    // the target, filled, then renamed, so it's never readable by others or half written
    readonly property string _privateWriteScript: [
        'umask 077',
        'mkdir -p "$1" && chmod 700 "$1" || exit 1',
        'tmp=$(mktemp "$1/.omatravel.XXXXXX") || exit 1',
        'if cat > "$tmp" && chmod 600 "$tmp" && mv -f "$tmp" "$2"; then exit 0; fi',
        'rm -f "$tmp"',
        'exit 1'].join("\n")

    function _writePrivate(proc, dir, file, text) {
        proc.running = false
        proc.command = ["sh", "-c", root._privateWriteScript, "sh", dir, file]
        proc.payload = text
        proc.stdinEnabled = true
        proc.running = true
    }

    // saving
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
            permTimer.restart()                     // setText creates the file with the default mode
        } else {                                    // really old quickshell
            _writePrivate(fallbackWriter, root.dataDir, root.storePath, text)
        }
    }

    function _say(msg) { notice = msg; noticeTimer.restart() }

    // places
    function addCountry(name) {
        name = Model.cleanName(Model.canonicalCountry(name))
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
        country = Model.cleanName(Model.canonicalCountry(country))
        city = Model.cleanName(city)
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
                Model.sanitize(s)                  // re-sorts and de-dupes the visits
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

    // remove one dated visit, the city stays
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
        country = Model.cleanName(Model.canonicalCountry(country))
        city = Model.cleanName(city)
        if (!country || !city) { _say("Pick a country (＋) and type a city."); return false }
        ensureIndex()
        _commit(function(s) {
            var p = s.profiles[s.activeProfile]
            if (!p.wishlist[country]) p.wishlist[country] = []
            if (p.wishlist[country].indexOf(city) === -1) p.wishlist[country].push(city)
        })
        return true
    }

    // wishlist place you've been to now: moves to visited cities
    // (add a date by adding the city again with one)
    function markVisited(country, city) {
        _commit(function(s) {
            var p = s.profiles[s.activeProfile]
            var wl = p.wishlist[country]
            if (wl) {
                p.wishlist[country] = wl.filter(function(c) { return c !== city })
                if (p.wishlist[country].length === 0) delete p.wishlist[country]
            }
            if (!p.countries[country]) p.countries[country] = { cities: [], city_meta: {} }
            if (p.countries[country].cities.indexOf(city) === -1) p.countries[country].cities.push(city)
        })
        _say(city + " moved to your visited cities.")
    }

    function removeWishlist(country, city) {
        _commit(function(s) {
            var wl = s.profiles[s.activeProfile].wishlist
            if (!wl[country]) return
            wl[country] = wl[country].filter(function(c) { return c !== city })
            if (wl[country].length === 0) delete wl[country]
        })
    }

    // profiles / look
    function createProfile(name) {
        name = Model.cleanName(name, 40)
        if (!name) return
        _commit(function(s) {
            if (!Object.prototype.hasOwnProperty.call(s.profiles, name)) s.profiles[name] = { countries: {}, wishlist: {} }
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
        _commit(function(s) { if (Object.prototype.hasOwnProperty.call(s.profiles, name)) s.activeProfile = name })
    }

    function setViewYear(y) { viewYear = (y > 0 && years.indexOf(y) !== -1) ? y : 0 }

    // export
    // writes the active profile to <data dir>/exports/. kind = csv | json
    function exportData(kind) {
        var stamp = new Date().toISOString().slice(0, 10)
        var text = kind === "json" ? Model.toJson(store, stamp) : Model.toCsv(store, allPoints)
        var file = dataDir + "/exports/omatravel-" + Model.fileSafe(store.activeProfile)
                   + "-" + stamp + (kind === "json" ? ".json" : ".csv")
        exporter.target = file
        _writePrivate(exporter, dataDir + "/exports", file, text)
    }

    // old versions kept theme and display options in travel-data.json.
    // copy anything that isn't the default into the settings store, once
    property bool _migrated: false
    function migrateLegacy() {
        if (_migrated || !settings || !settings.loaded || !storeReady) return
        _migrated = true
        var d = Model.display(store)
        var pairs = [["theme", store.theme, "auto"], ["icon", d.icon, "\ud83c\udf0d"],
                     ["showFlags", d.showFlags, true], ["showPath", d.showPath, true],
                     ["showPlaces", d.showPlaces, true],
                     ["maxTooltipCountries", d.maxTooltipCountries, 8],
                     ["maxTooltipCities", d.maxTooltipCities, 10]]
        for (var i = 0; i < pairs.length; i++)
            if (settings.get(pairs[i][0]) === null && pairs[i][1] !== undefined && pairs[i][1] !== pairs[i][2])
                settings.set(pairs[i][0], pairs[i][1])
    }
    onSettingsChanged: migrateLegacy()
    onStoreReadyChanged: migrateLegacy()
    Connections {
        target: root.settings
        function onLoadedChanged() { root.migrateLegacy() }
    }

    // map position of one of your cities, null if it has no pin
    function pointFor(country, city, kind) {
        var pts = allPoints, want = kind || "visited"
        for (var i = 0; i < pts.length; i++)
            if (pts[i].country === country && pts[i].name === city && pts[i].kind === want) return pts[i]
        return null
    }

    function formatKm(km) { return Model.formatKm(km) }

    // multi-line tooltip for the bar button
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

    // derived data
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

    // every dated visit in order (stable for equal dates), so a city visited twice
    // shows up twice and the path can come back to it
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

    // files
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

    // live omarchy theme
    // omarchy-theme-set deletes and recreates current/theme/, which kills any inotify watch
    // inside it. so colors are re-read with a short `cat`: on start, when theme.name changes
    // (that file survives), a bit after (swap may still be running), when switching to
    // follow omarchy, and on a slow poll while following
    readonly property string omarchyDir: configHome + "/omarchy/current"
    function _h2(v) { return ("0" + Math.round(v * 255).toString(16)).slice(-2) }
    function refreshSystemTheme() { if (!themeReader.running) themeReader.running = true }

    // dump the active theme's files (current/theme, else the named theme's folder)
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
                    // no current theme marker: pick the installed theme that matches the shell's colors
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
    onShellBgChanged: refreshSystemTheme()      // the shell recolors itself when the omarchy theme changes
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

    // process that gets its content on stdin, not argv (see _writePrivate).
    // writes the payload, drops its copy, closes stdin so cat sees EOF
    component StdinWriter: Process {
        property string payload: ""
        stdinEnabled: false
        onStarted: {
            write(payload)
            payload = ""
            stdinEnabled = false
        }
        onExited: payload = ""
    }

    // make the data dir, copy an old in-plugin save across once, then open the store
    Process {
        id: ensureDir
        command: ["sh", "-c",
            // travel history is personal: owner-only dirs and file, also ones from older builds
            "umask 077; mkdir -p \"$1\" && chmod 700 \"$1\" && { [ -f \"$2\" ] || { [ -f \"$3\" ] && cp \"$3\" \"$2\"; }; }; " +
            "[ -f \"$2\" ] && chmod 600 \"$2\"; [ -d \"$1/exports\" ] && chmod 700 \"$1/exports\"; true",
            "sh", root.dataDir, root.storePath, root.legacyStorePath]
        running: true
        onExited: root.storeReady = true
    }
    StdinWriter { id: fallbackWriter }
    // setText writes with the default umask and may recreate the file.
    // the 0700 dir already keeps others out, this puts the file back to 0600 after each save
    Process { id: permFixer; command: ["chmod", "600", root.storePath] }
    Timer {
        id: permTimer
        interval: 400
        onTriggered: { permFixer.running = false; permFixer.running = true }
    }
    StdinWriter {
        id: exporter
        property string target: ""
        onExited: function(code) {
            root._say(code === 0 ? "Exported to " + target.replace(Quickshell.env("HOME"), "~")
                                 : "Export failed (exit code " + code + ").")
        }
    }
    Timer { id: noticeTimer; interval: 6000; onTriggered: root.notice = "" }
}
