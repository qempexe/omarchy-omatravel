"""Drift check: SettingsPopup.qml (the schema), manifest.json and BarWidget.qml must agree.
Also: no native text input anywhere, balanced braces, helper files present."""
import json, os, re

root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
rd = lambda f: open(os.path.join(root, f), encoding="utf-8").read()

pop = rd("SettingsView.qml")
block = pop[pop.index("readonly property var sections: ["):pop.index("readonly property var defaults")]
schema = {}
for chunk in block.split('{ key: "')[1:]:
    if "fallback:" not in chunk:
        continue                                   # a `when` condition, not a setting
    key = chunk[:chunk.index('"')]
    kind = re.search(r'kind: "(\w+)"', chunk).group(1)
    fb = json.loads(re.search(r'fallback: ("(?:[^"\\]|\\.)*"|true|false|-?[\d.]+)', chunk).group(1))
    opts = re.search(r"options: (\[[^\]]*\])", chunk)
    mn, mx = re.search(r"min: (-?\d+)", chunk), re.search(r"max: (-?\d+)", chunk)
    schema[key] = dict(kind=kind, fallback=fb, options=json.loads(opts.group(1)) if opts else None,
                       min=int(mn.group(1)) if mn else None, max=int(mx.group(1)) if mx else None)

m = json.load(open(os.path.join(root, "manifest.json")))["barWidget"]
types = {"enum": "enum", "scheme": "enum", "int": "integer", "bool": "boolean", "string": "string", "color": "string"}
assert set(schema) == {s["key"] for s in m["schema"]} == set(m["defaults"]), "settings view / manifest keys differ"
for s in m["schema"]:
    p = schema[s["key"]]
    assert s["type"] == types[p["kind"]], s["key"] + ": type"
    assert s["defaultValue"] == p["fallback"] == m["defaults"][s["key"]], s["key"] + ": default"
    assert s.get("options") == p["options"], s["key"] + ": options"
    assert s.get("min") == p["min"] and s.get("max") == p["max"], s["key"] + ": range"

bar = rd("BarWidget.qml")
for key in schema:
    assert 'setting("%s"' % key in bar, "BarWidget.qml does not read " + key

for f in ("TravelModel.qml", "Panel.qml", "GlobeView.qml", "SettingsStore.qml", "SettingRow.qml", "SettingsView.qml", "PanelFrame.qml",
          "Model.js", "GlobeProjection.js", "manifest.json", "README.md"):
    assert os.path.isfile(os.path.join(root, f)), "missing " + f
for f in ("assets/earth.png", "data/layers/index.json", "data/layers/z0.json", "data/layers/z3.json"):
    assert os.path.isfile(os.path.join(root, f)), "missing " + f

assert not os.path.exists(os.path.join(root, "SettingsPopup.qml")), "settings live in the atlas panel, not a second popup"
assert "SettingsView {" in rd("Panel.qml"), "Panel.qml does not host the settings view"
assert "PanelFrame {" in rd("Panel.qml") and "KeyboardPanel" not in rd("Panel.qml"), "the atlas panel must live in PanelFrame"
# No QML file creates a native text element: those read the clipboard in the background
# while the panel is hidden. Text fields are drawn by SettingRow (settings) and FieldBox (atlas).
for f in os.listdir(root):
    if f.endswith(".qml"):
        t = rd(f)
        assert not re.search(r"\b(TextInput|TextField|TextArea|TextEdit)\b\s*\{", t), f + " creates a native text element"
for f in os.listdir(root):
    if f.endswith(".qml"):
        t = rd(f)
        assert "import QtQuick.Controls" not in t, f + " imports QtQuick.Controls"
        assert t.count("{") == t.count("}"), f + ": unbalanced braces"

# The old per-profile theme/display writers are gone; Panel must not call them.
panel = rd("Panel.qml")
for dead in ("setTheme(", "setIcon(", "setDisplayFlag(", "setShowFlags(", "setTooltipLimits("):
    assert dead not in panel, "Panel.qml still calls " + dead
# Every key the model reads through opt() exists in the schema.
model = rd("TravelModel.qml")
for key in re.findall(r'opt\("(\w+)"', model):
    assert key in schema, "TravelModel.qml reads an unknown setting: " + key
print("ok")
