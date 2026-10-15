import QtQuick
import Quickshell
import Quickshell.Io

// my own settings, in memory (instant) and in settings.json in the state dir.
// they win over setting(...). nothing goes to `omarchy bar set`, that rewrites
// the shell config and the whole shell reloads and freezes
Item {
    id: root

    property string pluginId: "io.github.qempexe.omatravel"
    property string stateDir: (Quickshell.env("XDG_STATE_HOME")
        || Quickshell.env("HOME") + "/.local/state") + "/omarchy-omatravel"
    property string path: stateDir + "/settings.json"

    property var values: ({})
    property bool loaded: false

    // edits made before settings.json is read. merged over the file once it loads,
    // so an early write can't replace the saved settings with an almost empty file
    property var pending: ({})
    property bool pendingAll: false     // a reset happened before the first load

    signal changed()
    // key that just changed ("*" = many, or edited outside)
    signal keyChanged(string key)

    function get(key) {
        var v = values[key]
        return v === undefined ? null : v
    }

    function set(key, value) {
        var next = {}
        for (var k in values) next[k] = values[k]
        if (value === null || value === undefined) delete next[key]
        else next[key] = value
        values = next
        if (!loaded && !pendingAll) {
            var p = {}
            for (var pk in pending) p[pk] = pending[pk]
            p[key] = (value === undefined) ? null : value
            pending = p
        }
        persist()
        changed()
        keyChanged(key)
    }

    function reset() {
        values = ({})
        if (!loaded) pendingAll = true
        persist()
        changed()
        keyChanged("*")
    }

    // back to the given defaults (stored explicitly, so nothing else shows through)
    function resetAll(defaults) {
        var next = {}
        for (var k in defaults) next[k] = defaults[k]
        values = next
        if (!loaded) pendingAll = true
        persist()
        changed()
        keyChanged("*")
    }

    // last few texts we wrote. the watcher reports our own writes back a moment later,
    // taking those in would roll settings back (sliders jumping), so they're skipped
    property var recent: []

    // writes are batched, the ui reads values from memory, no disk write per slider tick
    property bool dirty: false

    property double lastWrite: 0

    // first change goes out right away (a click is never lost), a burst after it once at the end
    function persist() {
        dirty = true
        if (!loaded) return              // written right after the file is read
        if (Date.now() - lastWrite > 300) writeNow()
        else writeTimer.restart()
    }

    function writeNow() {
        if (!dirty) return
        dirty = false
        lastWrite = Date.now()
        var text = JSON.stringify(values, null, 2) + "\n"
        var r = recent.slice(-7)
        r.push(text)
        recent = r
        echoTimer.restart()
        file.setText(text)
    }

    function absorb(text) {
        var raw = String(text || "")
        if (loaded) {
            // while our own write is pending or settling, whatever the watcher reports is ours
            // (can even be half written). taking it would flash old values back
            if (dirty || writeTimer.running || echoTimer.running) return
            if (recent.indexOf(raw) >= 0) return
        }
        var next = null
        try {
            var parsed = JSON.parse(raw)
            if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) next = parsed
        } catch (e) { }
        var wasLoaded = loaded
        if (!wasLoaded) {
            // first read: saved file + whatever was edited before it arrived
            var merged = {}
            if (!pendingAll && next !== null)
                for (var fk in next) merged[fk] = next[fk]
            if (pendingAll) {
                for (var vk in values) merged[vk] = values[vk]
            } else {
                for (var pk in pending) {
                    if (pending[pk] === null) delete merged[pk]
                    else merged[pk] = pending[pk]
                }
            }
            var touched = pendingAll || Object.keys(pending).length > 0
            values = merged
            pending = ({})
            pendingAll = false
            loaded = true
            if (touched) { dirty = true; writeNow() }
            return
        }
        if (next === null) return                  // empty or unreadable: keep what we have
        if (JSON.stringify(next) === JSON.stringify(values)) return
        values = next                              // edited somewhere else (another bar, by hand)
        if (wasLoaded) {
            changed()
            keyChanged("*")
        }
    }

    Component.onCompleted: mkdir.running = true
    Component.onDestruction: writeNow()

    Process {
        id: mkdir
        command: ["sh", "-c", 'umask 077; mkdir -p "$1" && chmod 700 "$1"', "sh", root.stateDir]
        onExited: file.reload()
    }

    Timer { id: echoTimer; interval: 1500; onTriggered: root.recent = [] }
    Timer { id: writeTimer; interval: 250; onTriggered: root.writeNow() }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        // text is a function on FileView, so call it. passing `text` gave absorb() the function
        // and the saved settings never came back
        onTextChanged: root.absorb(text())
        onLoaded: root.absorb(text())
        // no file yet (first run): nothing to restore, just start saving
        onLoadFailed: function(error) { root.absorb("") }
    }
}
