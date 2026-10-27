.pragma library

// Every setting Omatravel has: which tab and section it shows in, its options and its
// default. The settings tab, the bar widget, the model and the tests all read this, and
// manifest.json repeats it for the shell (tests/test_manifest.py keeps the two equal).
//
// An item: { key, label, kind, fallback, hint, section?, options?, labels?, presets?,
//            min?, max?, step?, divisor?, decimals?, maxLength?, when? }
//   kind  enum | int | bool | string | color
//   when  [{ key, is: [...] }]: the row is dimmed unless every one holds

var THEMES = ["auto", "custom", "catppuccin", "dracula", "everforest", "gruvbox", "kanagawa",
                "mono", "nord", "omarchy", "rose-pine", "tokyo-night"];
var OUTLINE = [{ key: "outline", is: [true] }];
var CUSTOM = [{ key: "theme", is: ["custom"] }];

var groups = [
    { key: "bar", title: "Bar", items: [
        { key: "icon", label: "Bar icon", kind: "string", fallback: "🌍", maxLength: 8,
          hint: "Up to 8 characters shown in the bar, for example an emoji." },
        { key: "showCounts", label: "Show counts", kind: "bool", fallback: true,
          hint: "Countries and cities next to the icon." },
        { key: "clickAction", label: "Left click", kind: "enum", fallback: "panel",
          options: ["panel", "settings", "none"],
          labels: { panel: "Open the atlas", settings: "Open settings", none: "Nothing" },
          hint: "What a left click on the widget does. Right click always opens the settings." },
        { key: "middleAction", label: "Middle click", kind: "enum", fallback: "none",
          options: ["none", "panel", "settings"],
          labels: { none: "Nothing", panel: "Open the atlas", settings: "Open settings" },
          hint: "What a middle click on the widget does." },
        { key: "maxTooltipCountries", label: "Countries in the tooltip", kind: "int", fallback: 8,
          min: 1, max: 30, step: 1,
          hint: "How many countries the bar tooltip lists before \"+ N more\"." },
        { key: "maxTooltipCities", label: "Cities per country", kind: "int", fallback: 10,
          min: 1, max: 30, step: 1,
          hint: "How many cities the tooltip lists under each country." }
    ] },
    { key: "globe", title: "Globe", items: [
        { key: "globeSide", label: "Globe side", kind: "enum", fallback: "left",
          options: ["left", "right"], labels: { left: "Left", right: "Right" },
          hint: "Which side of the atlas the globe sits on. Your lists take the other side." },
        { key: "showFlags", label: "Show flags", kind: "bool", fallback: true,
          hint: "Country flag emoji in the lists and the tooltip." },
        { key: "showPath", label: "Travel path on the globe", kind: "bool", fallback: true,
          hint: "Draw arcs between your dated visits, in order." },
        { key: "showPlaces", label: "City labels on the globe", kind: "bool", fallback: true,
          hint: "Label cities as you zoom in." }
    ] },
    { key: "look", title: "Look", items: [
        { key: "theme", label: "Atlas theme", kind: "enum", fallback: "auto", section: "Colors",
          options: THEMES, labels: { auto: "Follow Omarchy", custom: "Custom" },
          hint: "Colors of the atlas and the globe. Follow Omarchy updates the moment you switch your theme. Custom uses the three colors below." },
        { key: "customBg", label: "Background", kind: "color", fallback: "#1a1b26", maxLength: 7, section: "Colors",
          presets: ["#1a1b26", "#1e1e2e", "#1d2021", "#2e3440", "#191724", "#121216", "#0f0f0f", "#f2f2f4"],
          hint: "Pick one, or type a hex like #1a1b26.", when: CUSTOM },
        { key: "customFg", label: "Text", kind: "color", fallback: "#c0caf5", maxLength: 7, section: "Colors",
          presets: ["#c0caf5", "#cdd6f4", "#ebdbb2", "#d8dee9", "#e0def4", "#f2f2f4", "#e8dcc8", "#1a1b26"],
          hint: "Pick one, or type a hex like #c0caf5.", when: CUSTOM },
        { key: "accentColor", label: "Accent", kind: "color", fallback: "#7aa2f7", maxLength: 7, section: "Colors",
          presets: ["#ff6a1f", "#7aa2f7", "#bb9af7", "#7dcfff", "#9ece6a", "#e0af68", "#f7768e", "#c0caf5"],
          hint: "Selected parts, pins and the travel path.", when: CUSTOM },
        { key: "opacity", label: "Window opacity", kind: "int", fallback: 100, min: 50, max: 100, step: 1,
          section: "Window",
          hint: "How solid the atlas background is. Lower lets your wallpaper show through. Text, globe and buttons stay solid." },
        { key: "cornerRadius", label: "Roundness", kind: "int", fallback: 12, min: 0, max: 24, step: 2,
          section: "Window",
          hint: "Corners of the docked atlas. 0 is square, 24 is very round." },
        { key: "surfaceTint", label: "Window tint", kind: "int", fallback: 0, min: 0, max: 30, step: 1,
          section: "Window",
          hint: "How much of the accent color washes over the background. 0 keeps it plain." },
        { key: "outline", label: "Window outline", kind: "bool", fallback: false, section: "Window",
          hint: "Draw the edge of the docked atlas in color instead of a plain neutral line: the theme's window border gradient, one of its colors, or the accent." },
        { key: "outlineGradient", label: "Outline gradient", kind: "bool", fallback: true, section: "Window",
          hint: "When your theme's window border is a gradient, the outline runs through all its colors, at the same angle.",
          when: OUTLINE },
        { key: "outlineColor", label: "Outline color", kind: "enum", fallback: "accent", section: "Window",
          options: ["accent", "first", "middle", "last"],
          labels: { accent: "Accent", first: "Border's first", middle: "Border's middle", last: "Border's last" },
          hint: "The one color of the outline when it isn't a gradient. The border colors come from your theme's window border, and fall back to the accent when it has none.",
          when: OUTLINE },
        { key: "fontScale", label: "Text size", kind: "int", fallback: 100, min: 80, max: 150, step: 5,
          divisor: 100, decimals: 2, section: "Text",
          hint: "1 is normal, 1.25 is a quarter bigger." },
        { key: "density", label: "Spacing", kind: "enum", fallback: "comfortable", section: "Text",
          options: ["compact", "comfortable", "spacious"],
          labels: { compact: "Compact", comfortable: "Comfortable", spacious: "Spacious" },
          hint: "How much air there is around the edges of the atlas." }
    ] },
    { key: "window", title: "Window", items: [
        { key: "openAs", label: "Open as", kind: "enum", fallback: "panel",
          options: ["panel", "window"],
          labels: { panel: "Bar panel", window: "Own window" },
          hint: "Where the bar icon opens the atlas. You can always pop it out or dock it back from the header." },
        { key: "windowWidth", label: "Width", kind: "int", fallback: 1180, min: 800, max: 1800, step: 20,
          hint: "How wide the docked atlas opens." },
        { key: "windowHeight", label: "Height", kind: "int", fallback: 760, min: 500, max: 1200, step: 20,
          hint: "How tall the docked atlas opens. It never grows past the screen." }
    ] }
];

// ---- every item, by key ------------------------------------------------------------

var items = [];
var byKey = {};
for (const g of groups) {
    for (const it of g.items) {
        it.group = g.key;
        items.push(it);
        byKey[it.key] = it;
    }
}

var defaults = {};
for (const it of items) defaults[it.key] = it.fallback;

// a value as it may be used: the right type, inside its range, one of its options,
// or the default
function clean(key, v) {
    const it = byKey[key];
    if (!it) return undefined;
    if (v === undefined || v === null) return it.fallback;
    switch (it.kind) {
    case "bool":
        return v === true || v === "true" ? true : (v === false || v === "false" ? false : it.fallback);
    case "int": {
        const n = typeof v === "number" ? v : parseFloat(v);
        return isFinite(n) ? Math.max(it.min, Math.min(it.max, Math.round(n))) : it.fallback;
    }
    case "color":
        return typeof v === "string" && /^#[0-9a-fA-F]{6}$/.test(v.trim()) ? v.trim() : it.fallback;
    case "string":
        return typeof v === "string" ? v.replace(/[\u0000-\u001f\u007f]/g, "").slice(0, it.maxLength || 256) : it.fallback;
    default:
        return it.options.indexOf(String(v)) >= 0 ? String(v) : it.fallback;
    }
}

// is a row in effect with these values? (a function that reads one value)
function active(it, valueOf) {
    if (!it.when) return true;
    return it.when.every((c) => c.is.map(String).indexOf(String(valueOf(c.key))) >= 0);
}

// does a row match what was typed in the search box?
function matches(it, text) {
    const f = String(text || "").trim().toLowerCase();
    if (f === "") return true;
    const words = [it.label, it.hint, it.section || "", groupTitle(it.group)];
    for (const o of it.options || []) words.push(String(o), it.labels && it.labels[o] ? it.labels[o] : "");
    return words.join(" ").toLowerCase().indexOf(f) >= 0;
}

function groupTitle(key) {
    for (const g of groups) if (g.key === key) return g.title;
    return "";
}
