# Omatravel

An [Omarchy](https://omarchy.org) shell bar widget that keeps a spinning globe of everywhere you have been, and everywhere you want to go.

![Omatravel preview](preview.png)

Click the globe icon in the bar to open the atlas: drag to spin the globe, zoom in until city labels appear, log countries and cities (with as many dated visits as you like), and watch your travel path draw itself in order. Pop the whole panel out into its own window if you want it on a second monitor.

## Features

- **Interactive globe**: a GPU-shaded orthographic globe. Drag or flick to spin, scroll or use **+ / − / ⌖** to zoom (up to 40×) and recentre. Land, borders and graticule are coloured by your theme.
- **City labels as you zoom**: four population bands load on demand, from cities over 500,000 people out to every place over 1,000. Click a city on the globe to prefill the add form.
- **Places**: log countries and the cities you visited. A city can carry several dated visits (`2019`, `2019-05` or `2019-05-02`); repeat visits show as `Barcelona ×5`.
- **Travel path**: dated visits are joined by great-circle arcs in chronological order, so a city visited twice is returned to.
- **Wishlist**: pin places you want to visit in a second colour. When you get there, tick **✓** next to the city and it moves to your visited places.
- **Stats**: how many countries (and what share of the 195 world countries) and continents you have covered, the number of cities and dated visits, the total distance of your travel path in km and as laps around the Earth, your first and latest trip, your most-visited city and busiest year.
- **Time travel**: pick a year in **Stats** and the globe and travel path show your map as it stood at the end of that year. Undated cities and the wishlist always stay visible. The footer tells you when it is active.
- **Export**: save the active profile as **CSV** (one row per city, with status, visit dates and coordinates; opens in any spreadsheet) or as **JSON** (the full profile). Files are written to `~/.local/share/omatravel/exports/`.
- **Profiles**: keep separate maps (for example "me" and "family"). The default profile cannot be deleted.
- **Search**: filter your countries and cities from the header.
- **Flags**: optional country flag emoji in the list and tooltip.
- **Pop out**: detach the panel into a normal window. It stays popped out (the bar icon shows and hides the window) until you press **Dock**. Both variants always look identical.
- **Themes**: **Follow Omarchy** repaints the whole panel and globe with your live Omarchy theme and updates the moment you switch it, or pick one of ten fixed palettes.
- **Settings tab**: every option in plain language inside the same panel (right-click the bar icon to jump straight to it), with a hint under each setting and a reset arrow once it differs from the default. Changes apply instantly.
- **Bar button**: icon plus `countries · cities` (both optional), with a tooltip listing your countries, and configurable left and middle click.
- **Offline**: all map and city data ships inside the plugin. No network access.

## Install

```
omarchy plugin add https://github.com/qempexe/omarchy-omatravel.git --enable --yes
```

Or by hand: copy this directory to `~/.config/omarchy/plugins/io.github.qempexe.omatravel/` (the folder name must match the plugin id), then:

```
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.qempexe.omatravel
```

Add the widget to your bar layout in `~/.config/omarchy/shell.json`, under `bar` → `layout` → the section you want (`left`, `center` or `right`):

```
{ "id": "io.github.qempexe.omatravel" }
```

Then restart the shell:

```
omarchy restart shell
```

### See it work in 1 minute

Click the globe icon, type `Spain` in the **Country** box and press **Add**, then type `Barcelona`, a date such as `2024-06`, and press **Add city**. The globe pins it. Add a second dated city and an arc appears between them.

## Usage

| Action                          | How                                                              |
| ------------------------------- | ---------------------------------------------------------------- |
| Open / close the panel          | Left-click the globe icon                                        |
| Spin the globe                  | Drag or flick                                                    |
| Zoom                            | Scroll wheel, or **+** / **−**                                   |
| Recentre                        | **⌖**                                                            |
| Prefill the add form            | Click a city on the globe                                        |
| Select a country                | Click its row in **Places**                                      |
| Fly to a city                   | Click its chip                                                   |
| Log another visit               | Add the same city again with a new date                          |
| Remove a country, city or visit | **✕** next to it                                                 |
| Move a wishlist city to visited | **✓** next to it in **Wishlist**                                 |
| Show the map as of a year       | **Stats** tab → pick a year under *Time travel* (**All** resets) |
| Export the profile              | **Stats** tab → *Save as CSV* or *Save as JSON*                  |
| Pop out / dock back             | **Pop out** in the header; while popped out the bar icon shows / hides the window and **Dock** brings it back to the bar |
| Open the settings                | Right-click the bar icon, or the **Settings** tab                |
| Controls cheat-sheet            | **?** in the header                                              |
| Close                           | `Esc` or **✕**                                                   |

The panel has five tabs across the top: **Places**, **Wishlist**, **Stats**, **Profiles** and **Settings**. The "Add a place" form is docked at the bottom; flip its switch between **✓ Visited** and **♡ Wishlist** to choose where a city goes.

## Settings

Right-click the bar icon, or open the **Settings** tab. The tab has four sections: Bar, Globe, Look and Window. Everything applies instantly and is saved to `~/.local/state/omarchy-omatravel/settings.json`; edits made there by hand are picked up while the shell runs. **Reset all** (asks twice) puts every setting back to its default. Your places are not touched by any of this.

### Bar

| Setting | File key | Values | Default |
| --- | --- | --- | --- |
| Bar icon | `icon` | up to 8 characters | 🌍 |
| Show counts | `showCounts` | on / off | on |
| Left click | `clickAction` | `panel`, `settings`, `none` | `panel` |
| Middle click | `middleAction` | `none`, `panel`, `settings` | `none` |
| Countries in the tooltip | `maxTooltipCountries` | 1 to 30 | 8 |
| Cities per country | `maxTooltipCities` | 1 to 30 | 10 |

Right click always opens the settings.

### Globe

| Setting | File key | Default | Meaning |
| --- | --- | --- | --- |
| Show flags | `showFlags` | on | Flag emoji in the lists and the tooltip |
| Travel path on the globe | `showPath` | on | Draw arcs between dated visits |
| City labels on the globe | `showPlaces` | on | Label cities as you zoom |

### Look

| Setting | File key | Default | Meaning |
| --- | --- | --- | --- |
| Atlas theme | `theme` | `auto` | `auto` (Follow Omarchy), `custom`, or one of the named themes below |
| Background | `customBg` | `#1a1b26` | Custom theme background (shown when the theme is Custom) |
| Text | `customFg` | `#c0caf5` | Custom theme text (shown when the theme is Custom) |
| Accent | `accentColor` | `#7aa2f7` | Custom theme accent: selected parts, pins and the path (shown when the theme is Custom) |
| Opacity | `opacity` | 100 | Background opacity, 50 to 100. Text, globe and buttons stay solid |
| Roundness | `cornerRadius` | 12 | Corners of the docked atlas, 0 to 24 |
| Window outline | `outline` | off | Edge of the docked atlas in the accent color instead of a neutral line |
| Window tint | `surfaceTint` | 0 | How much of the accent washes over the background, 0 to 30 |
| Text size | `fontScale` | 100 | 80 to 150 (shown as 0.8 to 1.5) |
| Spacing | `density` | `comfortable` | `compact`, `comfortable` or `spacious` |

### Window

| Setting | File key | Default | Meaning |
| --- | --- | --- | --- |
| Open as | `openAs` | `panel` | `panel` (bar panel) or `window` (own window). Used until you press **Pop out** or **Dock** in the header |
| Width | `windowWidth` | 1180 | 800 to 1800. Docked atlas only: locked while popped out, since the window manager sizes the window |
| Height | `windowHeight` | 760 | 500 to 1200. Docked atlas only: locked while popped out. Never grows past the screen |

`activeProfile` and your places stay in `~/.local/share/omatravel/travel-data.json` (or `$XDG_DATA_HOME/omatravel/`). Cities are looked up by name in the bundled atlas. For a place it does not know, add `"lat"` and `"lng"` to its entry under `city_meta` in that file and it will be pinned there.

### Themes

`Follow Omarchy`, `Custom` (your own background, text and accent) plus: `catppuccin`, `dracula`, `everforest`, `gruvbox`, `kanagawa`, `mono`, `nord`, `omarchy`, `rose-pine`, `tokyo-night`.

## How it works

- **Following Omarchy**: the plugin reads the active theme's `colors.toml` (or the per-app files older Omarchy themes ship: `alacritty.toml`, `kitty.conf`, `waybar.css`, `btop.theme`, `mako.ini`, `hyprland.conf`) for background, text and accent. If your install has no "current theme" marker, it scans the themes in `~/.config/omarchy/themes` and picks the one that matches the colour your shell bar is using. It re-reads whenever that colour or `theme.name` changes, with a slow poll as a backstop. If nothing can be read it falls back to the shell's own colours.
- **The window**: docked, the atlas sits in `PanelFrame.qml`, a bar popup with a thin border and rounded corners placed flush against the bar's outer edge (it never covers the bar). `Esc`, the **✕** button or a click outside closes it.
- **One palette for both variants**: the docked panel and the detached window draw the same opaque background, text and accent, so they cannot drift apart.
- **The globe** is a fragment shader (`shaders/globe.frag`) sampling a land / border / graticule mask (`assets/earth.png`) and tinting it with the theme. Pins, arcs and labels are drawn on a canvas on top using the same projection maths (`GlobeProjection.js`).
- **City data** is split into four zoom bands (`z0`–`z3`, by population) plus a name → coordinates index. Bands are only read from disk when you zoom far enough to need them.
- **Stats and time travel** are computed from your saved places on every change. The distance is the great-circle length of the dated path, in order (Haversine formula, Earth radius 6,371 km).
- **Settings** are held by `SettingsStore.qml`: edits made before the file loads are kept, the plugin's own writes are not read back, and outside edits are picked up. `TravelModel.qml` reads every option through one helper, so the bar, the atlas and the globe always agree.
- **Saving** goes to a file outside the plugin folder, so Quickshell's hot-reload of the plugin directory never restarts your bar when you add a city.
- Text from your data and from the filesystem is always drawn as plain text, never rich text.

## Data and privacy

- Your settings live in `~/.local/state/omarchy-omatravel/settings.json`.
- Your places live in `~/.local/share/omatravel/travel-data.json`. Exports you request are written to `~/.local/share/omatravel/exports/` and nothing else is stored. An older save inside the plugin folder (`data/travel-data.json`) is copied across once.
- The only external process it runs is `sh`, for `mkdir`, `cp` and `printf` (creating the data folder, the one-off migration and writing exports), `cat`, `ls` and `find` (reading Omarchy's theme files under `~/.config/omarchy` and `~/.local/share/omarchy`) and `wl-paste` (only when you press Ctrl+V in a settings text field, at most 1 KB, for at most 2 seconds). **No network access, no telemetry.**
- Plugins run unsandboxed in the shell process. This one reads and writes only the files described here.

## Limitations

- City lookup knows places of 1,000 people or more. A city it cannot find is still saved and listed, but has no pin until you give it coordinates (see Settings).
- The globe needs a working Qt RHI shader backend. If it renders blank, rebuild the shaders with `tools/build-shaders.sh` (needs `qt6-shadertools`).
- With **Follow Omarchy**, if the shell tints or dims its own background, matching an installed theme by colour may fail and the shell's colours are used instead. The hint under the theme buttons says what it found.

## Files

| File                                          | Purpose                                                       |
| --------------------------------------------- | ------------------------------------------------------------- |
| `manifest.json`                               | Omarchy plugin manifest                                       |
| `BarWidget.qml`                               | Bar icon, tooltip and panel host                              |
| `Panel.qml`                                   | The atlas panel: header, sidebar tabs, add form, theming      |
| `PanelFrame.qml`                              | The bordered bar popup the atlas lives in: placement against the bar, click outside to close |
| `SettingsView.qml`                            | The Settings tab inside the panel (Bar, Globe, Look sections) |
| `SettingRow.qml`                              | One setting: segments, chips, slider, switch, text field, colors |
| `SettingsStore.qml`                           | `settings.json`: instant, merged on load, watched, echo-safe  |
| `TravelModel.qml`                             | State, persistence, data loading, live Omarchy theme          |
| `GlobeView.qml`                               | The globe: shader, pins, arcs, labels, zoom controls          |
| `Model.js`                                    | Pure logic: store, countries, dates, theme parsing, stats, export |
| `GlobeProjection.js`                          | Orthographic projection and great-circle maths                |
| `DetachedWindow.qml`                          | The pop-out window                                            |
| `FlatButton.qml`, `FieldBox.qml`, `SectionLabel.qml` | Small themed UI pieces                                 |
| `shaders/`                                    | `globe.vert` / `globe.frag` and their compiled `.qsb`         |
| `assets/earth.png`                            | Land / border / graticule mask                                |
| `data/layers/`                                | `z0`–`z3.json` city bands and `index.json` lookup             |
| `tools/`                                      | Build scripts for the shaders, texture and city data          |
| `preview.png`                                 | Title card used in this README and the marketplace            |
| `LICENSE`                                     | MIT licence                                                   |
| `tests/test_model.js`                         | Unit tests for the pure logic (`node tests/test_model.js`)    |
| `tests/test_manifest.py`                      | Drift check: settings view schema == `manifest.json` == the code that reads it |

## Development

Plugin files under `~/.config/omarchy/plugins/` are watched, but restart the shell to be sure you are running the latest code:

```
omarchy restart shell
```

To run the tests (no Qt needed):

```
node tests/test_model.js
python3 tests/test_manifest.py   # SettingsView.qml schema == manifest.json == BarWidget.qml / TravelModel.qml
```

To check the manifest:

```
omarchy plugin validate .
```

To lint the QML:

```
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml TravelModel.qml GlobeView.qml SettingsView.qml
```

The files in `assets/`, `shaders/*.qsb` and `data/layers/` are generated and committed, so installing needs none of this. To regenerate them (these scripts are the only part of the project that touch the network, and they are never run by the plugin):

```
tools/build-shaders.sh     # needs qt6-shadertools (qsb)
tools/build-texture.py     # needs python3 + pillow; downloads Natural Earth
tools/build-layers.py      # downloads GeoNames cities1000
```

## Updating from 1.1

The **Look** tab is now the **Settings** tab and has every option, including new ones (right-click the bar icon opens it). The first time 1.2.0 runs, any theme, icon, flag, path, label or tooltip value you had changed is copied across, so nothing is lost. Your places are untouched.

## Updating from 1.0

Nothing to migrate: the save format is unchanged. Stats, time travel and export are available straight away, and wishlist cities gain a **✓** button.

## Updating

```
omarchy plugin update io.github.qempexe.omatravel
omarchy restart shell
```

The first command pulls the latest version. The second is required because the shell does not reliably reload changed QML on its own.

## Uninstall

```
omarchy plugin remove io.github.qempexe.omatravel
```

If this does not edit `shell.json`: remove the `{ "id": "io.github.qempexe.omatravel" }` entry from your bar layout by hand. Then restart the shell:

```
omarchy restart shell
```

To also delete your saved places:

```
rm -rf ~/.local/share/omatravel
```

This is optional. Leave it if you might reinstall and want your map back.

## Changelog

### 1.2.0

- The docked atlas now lives in its own bordered popup window (`PanelFrame.qml`) with one 14 px inset on every edge.
- The atlas panel chrome is restyled: a rounded header card with a badge, title and live counts, underlined sidebar tabs, and an `Esc` close footer.
- New Settings tab inside the atlas panel (right-click the bar icon to open it) with Bar, Globe and Look sections, in plain language with hints and per-setting reset.
- New options: show counts, left and middle click actions, tooltip size.
- Theme and display options are saved in `~/.local/state/omarchy-omatravel/settings.json` and migrated once from `travel-data.json`.
- Manifest now declares every setting, checked by `tests/test_manifest.py`.
- New Look settings: Custom theme (background, text, accent), opacity, roundness, window outline, window tint, text size and spacing.
- New Window settings: open as bar panel or own window, width and height (docked atlas only; locked while popped out).
- Pop out and dock: the popped-out mode sticks until **Dock**, the bar icon shows and hides the window instead of docking it, and closing the window (✕ or Super+Q) only hides it.
- Fixed: pressing **Dock** in the pop-out window with no other window open no longer closes both the window and the docked panel; if the panel still cannot open, the window comes back instead of leaving nothing on screen.

### 1.1.0

- Stats, time travel, export and the wishlist **✓** button.

## License

[MIT](LICENSE)

### Third-party data

The code is MIT. The bundled data is derived from these sources, which keep their own terms:

- **City names and coordinates** (`data/layers/`): derived from [GeoNames](https://www.geonames.org) `cities1000`, licensed under [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/). Changes: filtered by population into zoom bands, reduced to name, country code, population and rounded coordinates, and indexed by folded name. Attribution to GeoNames is required if you reuse this data.
- **Land, borders and lakes** (`assets/earth.png`): rendered from [Natural Earth](https://www.naturalearthdata.com) 1:50m vector data, which is in the public domain.
- **Flags** are emoji drawn by your system font; nothing is bundled.

Omatravel is an independent community plugin. It is not affiliated with or endorsed by Omarchy or its authors.
