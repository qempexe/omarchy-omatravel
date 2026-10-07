.pragma library

// ───────────────────────── themes ─────────────────────────
var DEFAULT_THEMES = {
    omarchy:       { text: "#e8dcc8", background: "#1a1815", accent: "#d4a35a" },
    "tokyo-night": { text: "#c0caf5", background: "#1a1b26", accent: "#7aa2f7" },
    catppuccin:    { text: "#cdd6f4", background: "#1e1e2e", accent: "#cba6f7" },
    gruvbox:       { text: "#ebdbb2", background: "#1d2021", accent: "#fabd2f" },
    nord:          { text: "#d8dee9", background: "#2e3440", accent: "#88c0d0" },
    dracula:       { text: "#f8f8f2", background: "#282a36", accent: "#bd93f9" },
    "rose-pine":   { text: "#e0def4", background: "#191724", accent: "#ebbcba" },
    everforest:    { text: "#d3c6aa", background: "#2d353b", accent: "#a7c080" },
    kanagawa:      { text: "#dcd7ba", background: "#1f1f28", accent: "#7e9cd8" },
    mono:          { text: "#e0e0e0", background: "#141414", accent: "#aaaaaa" }
};

// ───────────────────────── countries ─────────────────────────
// ISO-3166 alpha-2 | canonical name | aliases (";"-separated)
var _COUNTRY_TABLE = [
"AF|Afghanistan","AX|Åland Islands|aland","AL|Albania","DZ|Algeria","AS|American Samoa","AD|Andorra","AO|Angola",
"AI|Anguilla","AQ|Antarctica","AG|Antigua and Barbuda|antigua","AR|Argentina","AM|Armenia","AW|Aruba","AU|Australia",
"AT|Austria","AZ|Azerbaijan","BS|Bahamas|the bahamas","BH|Bahrain","BD|Bangladesh","BB|Barbados","BY|Belarus",
"BE|Belgium|belgië;belgique;belgien","BZ|Belize","BJ|Benin","BM|Bermuda","BT|Bhutan","BO|Bolivia",
"BQ|Bonaire, Sint Eustatius and Saba|bonaire","BA|Bosnia and Herzegovina|bosnia","BW|Botswana","BV|Bouvet Island",
"BR|Brazil|brasil","IO|British Indian Ocean Territory","BN|Brunei|brunei darussalam","BG|Bulgaria","BF|Burkina Faso",
"BI|Burundi","CV|Cabo Verde|cape verde","KH|Cambodia","CM|Cameroon","CA|Canada","KY|Cayman Islands",
"CF|Central African Republic","TD|Chad","CL|Chile","CN|China|prc;people's republic of china","CX|Christmas Island",
"CC|Cocos Islands|cocos (keeling) islands","CO|Colombia","KM|Comoros","CG|Republic of the Congo|congo;congo-brazzaville",
"CD|DR Congo|democratic republic of the congo;drc;congo-kinshasa","CK|Cook Islands","CR|Costa Rica","CI|Côte d'Ivoire|ivory coast;cote d'ivoire",
"HR|Croatia","CU|Cuba","CW|Curaçao|curacao","CY|Cyprus","CZ|Czechia|czech republic;czech","DK|Denmark|danmark",
"DJ|Djibouti","DM|Dominica","DO|Dominican Republic","EC|Ecuador","EG|Egypt","SV|El Salvador","GQ|Equatorial Guinea",
"ER|Eritrea","EE|Estonia","SZ|Eswatini|swaziland","ET|Ethiopia","FK|Falkland Islands","FO|Faroe Islands|faroes",
"FJ|Fiji","FI|Finland","FR|France","GF|French Guiana","PF|French Polynesia|tahiti","TF|French Southern Territories",
"GA|Gabon","GM|Gambia|the gambia","GE|Georgia","DE|Germany|deutschland","GH|Ghana","GI|Gibraltar","GR|Greece",
"GL|Greenland","GD|Grenada","GP|Guadeloupe","GU|Guam","GT|Guatemala","GG|Guernsey","GN|Guinea","GW|Guinea-Bissau",
"GY|Guyana","HT|Haiti","HM|Heard Island and McDonald Islands","VA|Vatican City|holy see;vatican","HN|Honduras",
"HK|Hong Kong","HU|Hungary","IS|Iceland","IN|India","ID|Indonesia","IR|Iran","IQ|Iraq","IE|Ireland","IM|Isle of Man",
"IL|Israel","IT|Italy|italia","JM|Jamaica","JP|Japan","JE|Jersey","JO|Jordan","KZ|Kazakhstan","KE|Kenya","KI|Kiribati",
"KP|North Korea|dprk","KR|South Korea|korea;republic of korea","XK|Kosovo","KW|Kuwait","KG|Kyrgyzstan","LA|Laos",
"LV|Latvia","LB|Lebanon","LS|Lesotho","LR|Liberia","LY|Libya","LI|Liechtenstein","LT|Lithuania","LU|Luxembourg",
"MO|Macao|macau","MG|Madagascar","MW|Malawi","MY|Malaysia","MV|Maldives","ML|Mali","MT|Malta","MH|Marshall Islands",
"MQ|Martinique","MR|Mauritania","MU|Mauritius","YT|Mayotte","MX|Mexico|méxico","FM|Micronesia","MD|Moldova","MC|Monaco",
"MN|Mongolia","ME|Montenegro","MS|Montserrat","MA|Morocco","MZ|Mozambique","MM|Myanmar|burma","NA|Namibia","NR|Nauru",
"NP|Nepal","NL|Netherlands|the netherlands;holland;nederland","NC|New Caledonia","NZ|New Zealand|aotearoa","NI|Nicaragua",
"NE|Niger","NG|Nigeria","NU|Niue","NF|Norfolk Island","MK|North Macedonia|macedonia","MP|Northern Mariana Islands",
"NO|Norway|norge","OM|Oman","PK|Pakistan","PW|Palau","PS|Palestine|state of palestine;west bank;gaza","PA|Panama",
"PG|Papua New Guinea","PY|Paraguay","PE|Peru","PH|Philippines|the philippines","PN|Pitcairn Islands|pitcairn","PL|Poland|polska",
"PT|Portugal","PR|Puerto Rico","QA|Qatar","RE|Réunion|reunion","RO|Romania","RU|Russia|russian federation","RW|Rwanda",
"BL|Saint Barthélemy|saint barthelemy;st barths","SH|Saint Helena","KN|Saint Kitts and Nevis|st kitts and nevis;st kitts",
"LC|Saint Lucia|st lucia","MF|Saint Martin","PM|Saint Pierre and Miquelon","VC|Saint Vincent and the Grenadines|st vincent",
"WS|Samoa","SM|San Marino","ST|São Tomé and Príncipe|sao tome and principe","SA|Saudi Arabia","SN|Senegal","RS|Serbia",
"SC|Seychelles","SL|Sierra Leone","SG|Singapore","SX|Sint Maarten","SK|Slovakia","SI|Slovenia","SB|Solomon Islands",
"SO|Somalia","ZA|South Africa","GS|South Georgia and the South Sandwich Islands","SS|South Sudan","ES|Spain|españa",
"LK|Sri Lanka","SD|Sudan","SR|Suriname","SJ|Svalbard and Jan Mayen|svalbard","SE|Sweden|sverige","CH|Switzerland|schweiz;suisse;svizzera",
"SY|Syria","TW|Taiwan","TJ|Tajikistan","TZ|Tanzania","TH|Thailand","TL|Timor-Leste|east timor","TG|Togo","TK|Tokelau",
"TO|Tonga","TT|Trinidad and Tobago|trinidad","TN|Tunisia","TR|Turkey|türkiye;turkiye","TM|Turkmenistan","TC|Turks and Caicos Islands",
"TV|Tuvalu","UG|Uganda","UA|Ukraine","AE|United Arab Emirates|uae;emirates","GB|United Kingdom|uk;great britain;britain;england;scotland;wales;northern ireland",
"US|United States|usa;us;u.s.;u.s.a.;america;united states of america","UM|U.S. Minor Outlying Islands","UY|Uruguay","UZ|Uzbekistan",
"VU|Vanuatu","VE|Venezuela","VN|Vietnam|viet nam","VG|British Virgin Islands","VI|U.S. Virgin Islands","WF|Wallis and Futuna",
"EH|Western Sahara","YE|Yemen","ZM|Zambia","ZW|Zimbabwe"
];

var _byName = null;
var _byCode = null;

function fold(s) {
    s = String(s === undefined || s === null ? "" : s).toLowerCase();
    if (s.normalize) s = s.normalize("NFKD").replace(/[\u0300-\u036f]/g, "");
    return s.replace(/\s+/g, " ").trim();
}

function _init() {
    if (_byName) return;
    _byName = {}; _byCode = {};
    for (var i = 0; i < _COUNTRY_TABLE.length; i++) {
        var p = _COUNTRY_TABLE[i].split("|");
        var cc = p[0];
        _byCode[cc] = p[1];
        _byName[fold(p[1])] = cc;
        if (p[2]) {
            var al = p[2].split(";");
            for (var j = 0; j < al.length; j++) _byName[fold(al[j])] = cc;
        }
    }
}

// "Belgium" / "belgië" / "BE" / "the netherlands" -> "BE" | ""
function countryCode(name) {
    _init();
    var f = fold(name);
    if (!f) return "";
    if (_byName[f]) return _byName[f];
    if (f.indexOf("the ") === 0 && _byName[f.slice(4)]) return _byName[f.slice(4)];
    if (f.length === 2 && _byCode[f.toUpperCase()]) return f.toUpperCase();
    return "";
}

function countryName(code) { _init(); return _byCode[String(code).toUpperCase()] || ""; }

// Canonical display name for something the user typed ("uk" -> "United Kingdom").
function canonicalCountry(name) {
    var t = String(name === undefined || name === null ? "" : name).trim();
    var cc = countryCode(t);
    return cc ? countryName(cc) : t;
}

function allCountryNames() {
    _init();
    var out = [];
    for (var cc in _byCode) out.push(_byCode[cc]);
    out.sort();
    return out;
}

function countrySuggestions(prefix, limit) {
    _init();
    var f = fold(prefix), out = [];
    if (!f) return out;
    for (var cc in _byCode) {
        var n = _byCode[cc];
        if (fold(n).indexOf(f) === 0) out.push(n);
    }
    for (var alias in _byName) {
        if (alias.indexOf(f) === 0 && alias.length > 2) {
            var cn = _byCode[_byName[alias]];
            if (out.indexOf(cn) === -1) out.push(cn);
        }
    }
    out.sort();
    return out.slice(0, limit || 6);
}

function flagEmoji(country) {
    var code = countryCode(country);
    if (!code) return "🏳️";
    if (code === "XK") return "🇽🇰";
    return String.fromCodePoint(0x1F1E6 + code.charCodeAt(0) - 65)
         + String.fromCodePoint(0x1F1E6 + code.charCodeAt(1) - 65);
}

// English / common names the GeoNames local-name index doesn't contain.
var _CITY_ALIASES = {
    "ghent|be": "gent", "bruges|be": "brugge", "louvain|be": "leuven", "malines|be": "mechelen",
    "cologne|de": "koln", "hanover|de": "hannover",
    "seville|es": "sevilla", "saragossa|es": "zaragoza",
    "new york|us": "new york city", "nyc|us": "new york city", "la|us": "los angeles",
    "saigon|vn": "ho chi minh city", "peking|cn": "beijing", "canton|cn": "guangzhou",
    "bombay|in": "mumbai", "calcutta|in": "kolkata", "madras|in": "chennai",
    "constantinople|tr": "istanbul", "st petersburg|ru": "saint petersburg",
    "kiev|ua": "kyiv", "rangoon|mm": "yangon", "mexico|mx": "mexico city"
};

// Candidate keys into data/layers/index.json ("folded city|cc"), best first.
function indexKeys(city, country) {
    var cc = countryCode(country);
    if (!cc) return [];
    var c = fold(city), sfx = "|" + cc.toLowerCase();
    var keys = [c + sfx];
    var alias = _CITY_ALIASES[c.replace(/\./g, "") + sfx];
    if (alias) keys.push(alias + sfx);
    return keys;
}

function indexKey(city, country) {
    var k = indexKeys(city, country);
    return k.length ? k[0] : "";
}

// ───────────────────────── store ─────────────────────────
function _emptyProfile() { return { countries: {}, wishlist: {} }; }

function _empty() {
    return { profiles: { "default": _emptyProfile() }, activeProfile: "default",
             theme: "auto", display: {} };
}

// Make any parsed value safe to read and mutate.
function sanitize(store) {
    if (!store || typeof store !== "object" || Array.isArray(store)) return _empty();
    if (!store.profiles || typeof store.profiles !== "object") store.profiles = {};
    for (var name in store.profiles) {
        var p = store.profiles[name];
        if (!p || typeof p !== "object") p = store.profiles[name] = _emptyProfile();
        if (!p.countries || typeof p.countries !== "object") p.countries = {};
        if (!p.wishlist || typeof p.wishlist !== "object") p.wishlist = {};
        for (var c in p.countries) {
            var cd = p.countries[c];
            if (!cd || typeof cd !== "object") cd = p.countries[c] = {};
            if (!Array.isArray(cd.cities)) cd.cities = [];
            if (!cd.city_meta || typeof cd.city_meta !== "object") cd.city_meta = {};
            for (var city in cd.city_meta) _normalizeVisits(cd.city_meta[city]);
        }
        for (var w in p.wishlist) if (!Array.isArray(p.wishlist[w])) p.wishlist[w] = [];
    }
    if (!store.profiles["default"]) store.profiles["default"] = _emptyProfile();
    if (!store.profiles[store.activeProfile]) store.activeProfile = "default";
    if (store.theme !== "auto" && !DEFAULT_THEMES[store.theme]) store.theme = "auto";
    if (!store.display || typeof store.display !== "object") store.display = {};
    return store;
}

// A city can be visited many times: city_meta[city].visits = ["2019-05", "2023-08-02", ...]
// (sorted oldest first). Old saves had a single `date`; fold it into `visits`.
function _normalizeVisits(meta) {
    if (!meta || typeof meta !== "object") return;
    var raw = Array.isArray(meta.visits) ? meta.visits.slice() : [];
    if (meta.date) raw.push(meta.date);
    delete meta.date;
    var seen = {}, out = [];
    for (var i = 0; i < raw.length; i++) {
        var d = normalizeDate(raw[i]);
        if (d && !seen[d]) { seen[d] = true; out.push(d); }
    }
    out.sort(function(a, b) { var x = dateKey(a), y = dateKey(b); return x < y ? -1 : x > y ? 1 : 0; });
    if (out.length) meta.visits = out; else delete meta.visits;
}

function visitsOf(meta) {
    return meta && Array.isArray(meta.visits) ? meta.visits.slice() : [];
}

function parseStore(rawJson) {
    var s;
    try { s = JSON.parse(rawJson); } catch (e) { return _empty(); }
    return sanitize(s);
}

function activeProfile(store) {
    return store.profiles[store.activeProfile] || _emptyProfile();
}

function countryCount(store) { return Object.keys(activeProfile(store).countries).length; }

function cityCount(store) {
    var cs = activeProfile(store).countries, n = 0;
    for (var k in cs) n += (cs[k].cities || []).length;
    return n;
}

function countryRows(store) {
    var cs = activeProfile(store).countries, rows = [];
    for (var name in cs) {
        var cities = (cs[name].cities || []).slice();
        cities.sort();
        rows.push({ name: name, flag: flagEmoji(name), cities: cities, cityCount: cities.length });
    }
    rows.sort(function(a, b) {
        if (b.cityCount !== a.cityCount) return b.cityCount - a.cityCount;
        return a.name.localeCompare(b.name);
    });
    return rows;
}

function wishlistRows(store) {
    var wl = activeProfile(store).wishlist, rows = [];
    for (var country in wl) {
        var cities = wl[country].slice();
        cities.sort();
        rows.push({ country: country, flag: flagEmoji(country), cities: cities });
    }
    rows.sort(function(a, b) { return a.country.localeCompare(b.country); });
    return rows;
}

function profileNames(store) { return Object.keys(store.profiles || {}).sort(); }
function themeNames() { return Object.keys(DEFAULT_THEMES).sort(); }
// "auto" = follow the live Omarchy theme (`system` = parseSystemTheme() result, or null).
function themeColor(name, system) {
    if (name === "auto") return (system || DEFAULT_THEMES.omarchy).accent;
    return (DEFAULT_THEMES[name] || DEFAULT_THEMES.omarchy).accent;
}
function themeFor(store, system) {
    if (store.theme === "auto") return system || DEFAULT_THEMES.omarchy;
    return DEFAULT_THEMES[store.theme] || DEFAULT_THEMES.omarchy;
}

// ── Omarchy theme reader ─────────────────────────────────────────────────────
// TravelModel dumps the files of the active Omarchy theme, each introduced by "@@FILE <name>"
// (and "@@NAME <theme>"). Omarchy versions differ: new ones ship colors.toml, older ones only the
// per-app files, so every one of them is understood and the first that yields colours wins.
function _hex(v) {
    var m = /^(?:#|0x)?([0-9a-fA-F]{6})(?:[0-9a-fA-F]{2})?$/.exec(String(v).trim());
    return m ? "#" + m[1].toLowerCase() : "";
}

function parseOmarchyTheme(text) {
    var files = {}, cur = null, curName = "", sec = "", name = "";
    var lines = String(text === undefined || text === null ? "" : text).split(/\r?\n/);
    for (var i = 0; i < lines.length; i++) {
        var ln = lines[i], m;
        if ((m = /^@@NAME\s*(.*)$/.exec(ln))) { name = m[1].trim(); continue; }
        if ((m = /^@@FILE\s+(\S+)\s*$/.exec(ln))) { curName = m[1]; cur = files[curName] = {}; sec = ""; continue; }
        if (!cur) continue;
        var h;
        if (curName === "colors.toml") {                      // background = "#1a1b26"
            m = /^\s*([A-Za-z0-9_]+)\s*=\s*["']?((?:#|0x)?[0-9a-fA-F]{6})["']?/.exec(ln);
            if (m && !(m[1] in cur)) cur[m[1]] = _hex(m[2]);
        } else if (curName === "alacritty.toml") {            // [colors.primary]  background = "#1a1b26"
            if ((m = /^\s*\[([^\]]+)\]/.exec(ln))) { sec = m[1].trim(); continue; }
            m = /^\s*([A-Za-z0-9_]+)\s*=\s*["']([^"']+)["']/.exec(ln);
            if (m && (h = _hex(m[2])) && !((sec + "." + m[1]) in cur)) cur[sec + "." + m[1]] = h;
        } else if (curName === "kitty.conf") {                // background #1a1b26
            m = /^\s*(foreground|background|cursor|color4)\s+((?:#|0x)?[0-9a-fA-F]{6})\s*$/.exec(ln);
            if (m && !(m[1] in cur)) cur[m[1]] = _hex(m[2]);
        } else if (curName === "waybar.css") {                // @define-color background #1a1b26;
            m = /@define-color\s+([\w-]+)\s+(#[0-9a-fA-F]{6})/.exec(ln);
            if (m && !(m[1] in cur)) cur[m[1]] = _hex(m[2]);
        } else if (curName === "btop.theme") {                // theme[main_bg]="#1a1b26"
            m = /^\s*theme\[(\w+)\]\s*=\s*"(#[0-9a-fA-F]{6})"/.exec(ln);
            if (m && !(m[1] in cur)) cur[m[1]] = _hex(m[2]);
        } else if (curName === "mako.ini") {                  // background-color=#1a1b26ee
            m = /^\s*([a-z-]+)\s*=\s*(#[0-9a-fA-F]{6})/.exec(ln);
            if (m && !(m[1] in cur)) cur[m[1]] = _hex(m[2]);
        } else if (curName === "hyprland.conf") {             // $activeBorderColor = rgb(7aa2f7)
            m = /active_?border\w*\s*=.*?rgba?\(([0-9a-fA-F]{6})/i.exec(ln);
            if (m && !cur.accent) cur.accent = _hex(m[1]);
        }
    }
    var c = files["colors.toml"] || {}, a = files["alacritty.toml"] || {}, k = files["kitty.conf"] || {},
        w = files["waybar.css"] || {}, b = files["btop.theme"] || {}, mk = files["mako.ini"] || {},
        hy = files["hyprland.conf"] || {};
    var bg = c.background || a["colors.primary.background"] || k.background || w.background
             || b.main_bg || mk["background-color"] || "";
    var fg = c.foreground || a["colors.primary.foreground"] || k.foreground || w.foreground
             || b.main_fg || mk["text-color"] || "";
    if (!bg || !fg) return null;
    var accent = c.accent || hy.accent || b.hi_fg || mk["border-color"] || k.color4
                 || a["colors.normal.blue"] || c.color4 || k.cursor || a["colors.cursor.cursor"] || fg;
    var src = "";
    var order = ["colors.toml", "alacritty.toml", "kitty.conf", "waybar.css", "btop.theme", "mako.ini"];
    for (var j = 0; j < order.length && !src; j++) if (files[order[j]] && Object.keys(files[order[j]]).length) src = order[j];
    return { text: fg, background: bg, accent: accent, name: name, source: src };
}

// "@@THEME <name>" sections (every installed theme) -> [{name, text, background, accent, ...}]
function parseOmarchyThemes(text) {
    var out = [], chunks = String(text === undefined || text === null ? "" : text).split(/^@@THEME\s+/m);
    for (var i = 1; i < chunks.length; i++) {
        var nl = chunks[i].indexOf("\n");
        var nm = (nl < 0 ? chunks[i] : chunks[i].slice(0, nl)).trim();
        var t = parseOmarchyTheme("@@NAME " + nm + "\n" + (nl < 0 ? "" : chunks[i].slice(nl + 1)));
        if (t) out.push(t);
    }
    return out;
}

function _dist(a, b) {                                  // 0..1 distance between two "#rrggbb"
    var x = parseInt(a.slice(1), 16), y = parseInt(b.slice(1), 16), s = 0;
    for (var sh = 0; sh < 24; sh += 8) { var d = ((x >> sh) & 255) - ((y >> sh) & 255); s += d * d; }
    return Math.sqrt(s) / 441.67;
}

// The installed theme whose background is nearest to `bgHex` -> {theme, dist} or null.
function closestTheme(list, bgHex) {
    var best = null;
    for (var i = 0; i < list.length; i++) {
        var d = _dist(list[i].background, bgHex);
        if (!best || d < best.dist) best = { theme: list[i], dist: d };
    }
    return best;
}

// Plain colors.toml text only (kept for compatibility).
function parseSystemTheme(text) { return parseOmarchyTheme("@@FILE colors.toml\n" + text); }

// The bar button and its tooltip are drawn by the shell, which may auto-detect rich text.
// Neutralise markup in anything user- or file-supplied that is handed to it.
function plain(s) {
    return String(s === undefined || s === null ? "" : s).replace(/</g, "\u2039").replace(/>/g, "\u203a");
}

function display(store) {
    var d = store.display || {};
    return {
        icon: plain(d.icon) || "🌍",
        showFlags: d.showFlags !== false,
        showPath: d.showPath !== false,
        showPlaces: d.showPlaces !== false,
        maxTooltipCountries: d.maxTooltipCountries || 8,
        maxTooltipCities: d.maxTooltipCities || 10
    };
}

// ───────────────────────── date / path helpers ─────────────────────────
// Accepts YYYY, YYYY-MM or YYYY-MM-DD; returns normalised string or "" if invalid.
function normalizeDate(s) {
    s = String(s === undefined || s === null ? "" : s).trim();
    if (!s) return "";
    var m = /^(\d{4})(?:-(\d{1,2})(?:-(\d{1,2}))?)?$/.exec(s);
    if (!m) return null;                         // null = invalid
    var y = m[1], mo = m[2], d = m[3];
    if (mo !== undefined && (+mo < 1 || +mo > 12)) return null;
    if (d !== undefined && (+d < 1 || +d > 31)) return null;
    var out = y;
    if (mo !== undefined) out += "-" + ("0" + mo).slice(-2);
    if (d !== undefined) out += "-" + ("0" + d).slice(-2);
    return out;
}

// Sort key that places "2019" before "2019-05" before "2019-05-02".
function dateKey(s) {
    if (!s) return "9999-99-99";
    var p = String(s).split("-");
    return p[0] + "-" + (p[1] || "00") + "-" + (p[2] || "00");
}

// ───────────────────────── continents ─────────────────────────
var _CONTINENTS = {
    "Africa": "DZ AO BJ BW BF BI CV CM CF TD KM CG CD CI DJ EG GQ ER SZ ET GA GM GH GN GW KE LS LR LY MG MW ML MR MU YT MA MZ NA NE NG RE RW SH ST SN SC SL SO ZA SS SD TZ TG TN UG EH ZM ZW",
    "Asia": "AF AM AZ BH BD BT BN KH CN CY GE HK IN ID IR IQ IL JP JO KZ KP KR KW KG LA LB MO MY MV MN MM NP OM PK PS PH QA SA SG LK SY TW TJ TH TL TR TM AE UZ VN YE IO CX CC",
    "Europe": "AX AL AD AT BY BE BA BG HR CZ DK EE FO FI FR DE GI GR GG VA HU IS IE IM IT JE XK LV LI LT LU MT MD MC ME NL MK NO PL PT RO RU SM RS SK SI ES SJ SE CH UA GB",
    "North America": "AI AG AW BS BB BZ BM BQ VG CA KY CR CU CW DM DO SV GL GD GP GT HT HN JM MQ MX MS NI PA PR BL KN LC MF PM VC SX TT TC US VI",
    "South America": "AR BO BR CL CO EC FK GF GY PY PE SR UY VE GS",
    "Oceania": "AS AU CK FJ PF GU KI MH FM NR NC NZ NU NF MP PW PG PN WS SB TK TO TV UM VU WF",
    "Antarctica": "AQ BV HM TF"
};
var CONTINENT_NAMES = ["Africa", "Antarctica", "Asia", "Europe", "North America", "Oceania", "South America"];

// Territories and disputed places: they count as visited countries in the list, but not towards the
// "x of 195" world total (193 UN members + the Holy See + Palestine).
var _NOT_SOVEREIGN = " AX AS AI AQ AW BM BQ BV IO KY CX CC CK CW FK FO GF PF TF GI GL GP GU GG HM HK IM JE MO MQ YT MS NC NU NF MP PN PR RE BL SH MF PM SX SJ GS TK TC UM VG VI WF EH XK TW ";
var WORLD_COUNTRIES = 195;

var _continentByCode = null;
function continentOf(country) {
    if (!_continentByCode) {
        _continentByCode = {};
        for (var c in _CONTINENTS) {
            var codes = _CONTINENTS[c].split(" ");
            for (var i = 0; i < codes.length; i++) _continentByCode[codes[i]] = c;
        }
    }
    return _continentByCode[countryCode(country)] || "";
}

function isSovereign(country) {
    var cc = countryCode(country);
    return !!cc && _NOT_SOVEREIGN.indexOf(" " + cc + " ") === -1;
}

// ───────────────────────── distance, stats, time filter, export ─────────────────────────
var EARTH_KM = 6371.0088;

function haversineKm(lat1, lng1, lat2, lng2) {
    var r = Math.PI / 180;
    var dLat = (lat2 - lat1) * r, dLng = (lng2 - lng1) * r;
    var a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
          + Math.cos(lat1 * r) * Math.cos(lat2 * r) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
    return 2 * EARTH_KM * Math.asin(Math.min(1, Math.sqrt(a)));
}

// Length of the travel path (chronological points with lat/lng), in km.
function pathDistanceKm(path) {
    var km = 0;
    for (var i = 1; i < path.length; i++)
        km += haversineKm(path[i - 1].lat, path[i - 1].lng, path[i].lat, path[i].lng);
    return km;
}

function yearOf(date) {
    var m = /^(\d{4})/.exec(String(date || ""));
    return m ? parseInt(m[1], 10) : 0;
}

// Years that have at least one dated visit in the active profile, oldest first.
function visitYears(store) {
    var cs = activeProfile(store).countries, seen = {}, out = [];
    for (var c in cs) {
        var meta = cs[c].city_meta || {};
        for (var city in meta) {
            var v = visitsOf(meta[city]);
            for (var i = 0; i < v.length; i++) {
                var y = yearOf(v[i]);
                if (y && !seen[y]) { seen[y] = true; out.push(y); }
            }
        }
    }
    out.sort(function(a, b) { return a - b; });
    return out;
}

// Globe points as they looked at the end of `year` (0 = no filter): later visits drop out, and a
// city whose every visit is later disappears. Undated cities and the wishlist always stay.
function filterByYear(points, year) {
    if (!year) return points;
    var out = [];
    for (var i = 0; i < points.length; i++) {
        var p = points[i];
        if (p.kind !== "visited" || !p.visits.length) { out.push(p); continue; }
        var keep = p.visits.filter(function(d) { var y = yearOf(d); return y && y <= year; });
        if (!keep.length) continue;
        out.push({ lat: p.lat, lng: p.lng, name: p.name, country: p.country, kind: p.kind,
                   visits: keep, visitCount: keep.length, date: keep[keep.length - 1] });
    }
    return out;
}

// Everything the Stats tab shows. `path` = chronological points with lat/lng (all years).
function computeStats(store, path) {
    var prof = activeProfile(store), cs = prof.countries;
    var st = { countries: 0, sovereign: 0, worldPercent: 0, continents: [], continentCount: 0,
               cities: 0, visits: 0, datedCities: 0, distanceKm: 0, laps: 0,
               first: "", last: "", topCity: null, busiestYear: null, years: [] };
    var cont = {}, perYear = {}, firstKey = "", lastKey = "";
    for (var name in cs) {
        st.countries++;
        if (isSovereign(name)) st.sovereign++;
        var ct = continentOf(name);
        if (ct) cont[ct] = true;
        var cd = cs[name], cities = cd.cities || [];
        st.cities += cities.length;
        for (var i = 0; i < cities.length; i++) {
            var v = visitsOf((cd.city_meta || {})[cities[i]]);
            if (!v.length) continue;
            st.datedCities++;
            st.visits += v.length;
            if (!st.topCity || v.length > st.topCity.count)
                st.topCity = { name: cities[i], country: name, count: v.length };
            for (var j = 0; j < v.length; j++) {
                var k = dateKey(v[j]), y = yearOf(v[j]);
                if (!firstKey || k < firstKey) { firstKey = k; st.first = v[j]; }
                if (!lastKey || k > lastKey) { lastKey = k; st.last = v[j]; }
                if (y) perYear[y] = (perYear[y] || 0) + 1;
            }
        }
    }
    st.worldPercent = Math.round(st.sovereign / WORLD_COUNTRIES * 1000) / 10;
    st.continents = CONTINENT_NAMES.filter(function(c) { return cont[c]; });
    st.continentCount = st.continents.length;
    st.distanceKm = Math.round(pathDistanceKm(path || []));
    st.laps = Math.round(st.distanceKm / 40075.017 * 100) / 100;
    for (var yr in perYear) st.years.push({ year: parseInt(yr, 10), trips: perYear[yr] });
    st.years.sort(function(a, b) { return a.year - b.year; });
    for (var n = 0; n < st.years.length; n++)
        if (!st.busiestYear || st.years[n].trips > st.busiestYear.trips) st.busiestYear = st.years[n];
    return st;
}

function formatKm(km) {
    return String(Math.round(km)).replace(/\B(?=(\d{3})+(?!\d))/g, ",") + " km";
}

// CSV cell: quoted when needed; a leading = + - @ is defused so spreadsheets don't run it as a formula.
function csvCell(v) {
    var s = String(v === undefined || v === null ? "" : v);
    if (/^[=+\-@\t\r]/.test(s) && !/^-?\d+(\.\d+)?$/.test(s)) s = "'" + s;   // numbers stay numbers
    return /[",\r\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
}

// One row per city: country, city, status, visits ("2019;2023-08"), lat, lng. `points` supplies coordinates.
function toCsv(store, points) {
    var prof = activeProfile(store), where = {};
    for (var i = 0; i < (points || []).length; i++) where[points[i].kind + "|" + points[i].country + "|" + points[i].name] = points[i];
    var rows = [["country", "city", "status", "visits", "lat", "lng"]];
    function row(country, city, kind, visits) {
        var p = where[kind + "|" + country + "|" + city];
        rows.push([country, city, kind, visits.join(";"), p ? p.lat : "", p ? p.lng : ""]);
    }
    var cs = prof.countries, names = Object.keys(cs).sort();
    for (var a = 0; a < names.length; a++) {
        var cd = cs[names[a]], cities = (cd.cities || []).slice().sort();
        if (!cities.length) rows.push([names[a], "", "visited", "", "", ""]);
        for (var b = 0; b < cities.length; b++) row(names[a], cities[b], "visited", visitsOf((cd.city_meta || {})[cities[b]]));
    }
    var wl = prof.wishlist, wn = Object.keys(wl).sort();
    for (var c = 0; c < wn.length; c++) {
        var wcs = wl[wn[c]].slice().sort();
        for (var d = 0; d < wcs.length; d++) row(wn[c], wcs[d], "wishlist", []);
    }
    return rows.map(function(r) { return r.map(csvCell).join(","); }).join("\n") + "\n";
}

function toJson(store, exportedAt) {
    var p = activeProfile(store);
    return JSON.stringify({ app: "omatravel", profile: store.activeProfile, exportedAt: exportedAt || "",
                            countries: p.countries, wishlist: p.wishlist }, null, 2) + "\n";
}

// Safe file-name part for an export ("My trips!" -> "My_trips_").
function fileSafe(s) {
    return String(s === undefined || s === null ? "" : s).replace(/[^A-Za-z0-9_-]+/g, "_").slice(0, 40) || "profile";
}
