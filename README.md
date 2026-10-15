# Omatravel

**Your trips on a spinning globe, one click away in the [Omarchy](https://omarchy.org) bar.**

![Omatravel](preview.png)

I like looking back at where I've been, but every travel app wanted an account,
a subscription or my location. So I made a small atlas that lives in the bar,
works offline and keeps everything in one file on my machine. Click the 🌍,
spin the world, add a city.

## Install

```bash
omarchy plugin add https://github.com/qempexe/omarchy-omatravel.git --enable --yes
omarchy restart shell
```

Then put **Omatravel** in your bar, from the bar settings or with
`{ "id": "io.github.qempexe.omatravel" }` under `bar` → `layout` in
`~/.config/omarchy/shell.json`.

## Your first trip, in a minute

1. Click the globe icon in the bar.
2. Type `Spain` in **Country** and press **Add**.
3. Type `Barcelona`, a date like `2024-06`, and press **Add city**. It gets a pin.
4. Add another city with a date. An arc appears between the two, pointing the way
   you went.

Dates can be as rough as you remember them: `2019`, `2019-05` or `2019-05-02`.
Went back? Add the same city with a new date and it becomes `Barcelona ×2`.

---

## A quick tour

### Places

The globe on the left, your countries on the right. Every dated visit is linked
to the next one with a great-circle arc, so the lines are the actual order you
travelled in. This is my Europe:

![Places](screenshots/places.png)

Zoom in and more cities get labels, from the big ones down to places with 1,000
people. Click any of them and it's filled into the add form for you.

### Wishlist

The places you still want to see, pinned in a second color. Once you've been,
press **✓** and the city moves over to your visited places.

![Wishlist](screenshots/wishlist.png)

### Stats and time travel

How many countries (and how much of the 195 that is), continents, cities and
visits, how far you've travelled in km and in laps around the Earth, your first
and latest trip, most visited city and busiest year.

Underneath is the fun bit: pick a year and the globe goes back to how your map
looked at the end of it.

<table>
<tr>
<td><img src="screenshots/stats.png" alt="Stats"></td>
<td><img src="screenshots/time-travel.png" alt="Time travel, back to 2022"></td>
</tr>
<tr>
<td align="center"><sub>everything</sub></td>
<td align="center"><sub>back to the end of 2022</sub></td>
</tr>
</table>

From here you can also export the active profile, as **CSV** for a spreadsheet
or as **JSON**.

### Profiles

<img align="right" src="screenshots/profiles.png" alt="Profiles" width="300">

Separate maps with their own places and wishlist: one for you, one for family
trips, one for that road trip you keep planning. Switch whenever you like. The
`default` profile is the one that can't be deleted.

The header also has a search box for your countries and cities, **Pop out** to
move the whole atlas into its own window (handy on a second monitor), and **?**
for the cheat sheet below.

<br clear="right">

![Controls](screenshots/controls.png)

| | |
| --- | --- |
| Spin / zoom | drag or flick, scroll or **+ −**, **⌖** recenters |
| Fly to a city | click its chip in Places |
| Remove something | the **✕** next to it (a country, a city or one visit) |
| Visited or wishlist | the switch at the bottom of the add form |
| Pop out / back | **Pop out**, then the bar icon shows and hides the window until you press **Dock** |
| Settings | right click the bar icon |
| Close | `Esc` |

---

## Make it yours

Out of the box it follows your Omarchy theme and repaints the moment you switch.
There are ten built-in themes too (`catppuccin`, `dracula`, `everforest`,
`gruvbox`, `kanagawa`, `mono`, `nord`, `omarchy`, `rose-pine`, `tokyo-night`), or
**Custom** with your own background, text and accent. The screenshots above use a
custom brown one. Tokyo Night, Gruvbox, Catppuccin and Rosé Pine:

![Four of the themes](screenshots/themes.png)

Everything else is in the **Settings** tab (right click the bar icon to jump
there). Changes apply right away, anything you've changed gets a ↺, and **Reset all**
(click twice) puts it all back. Your places are never touched by any of it.

<details>
<summary><b>Bar</b>: icon, counts, clicks, tooltip</summary>
<br>
<p align="center"><img src="screenshots/settings-bar.png" alt="Bar settings" width="440"></p>

| Setting | Key | Values | Default |
| --- | --- | --- | --- |
| Bar icon | `icon` | up to 8 characters | 🌍 |
| Show counts | `showCounts` | on / off | on |
| Left click | `clickAction` | `panel`, `settings`, `none` | `panel` |
| Middle click | `middleAction` | `none`, `panel`, `settings` | `none` |
| Countries in the tooltip | `maxTooltipCountries` | 1 to 30 | 8 |
| Cities per country | `maxTooltipCities` | 1 to 30 | 10 |

Right click always opens the settings.
</details>

<details>
<summary><b>Globe</b>: flags, path, labels</summary>
<br>
<p align="center"><img src="screenshots/settings-globe.png" alt="Globe settings" width="440"></p>

| Setting | Key | Default | |
| --- | --- | --- | --- |
| Show flags | `showFlags` | on | flags in the lists and the tooltip |
| Travel path on the globe | `showPath` | on | arcs between dated visits |
| City labels on the globe | `showPlaces` | on | labels as you zoom |
</details>

<details>
<summary><b>Look</b>: theme, colors, opacity, roundness, text size</summary>
<br>
<p align="center"><img src="screenshots/settings-look.png" alt="Look settings" width="440"></p>

| Setting | Key | Default | |
| --- | --- | --- | --- |
| Atlas theme | `theme` | `auto` | `auto` (follow Omarchy), `custom`, or a built-in one |
| Background | `customBg` | `#1a1b26` | custom theme only |
| Text | `customFg` | `#c0caf5` | custom theme only |
| Accent | `accentColor` | `#7aa2f7` | custom theme only: selections, pins and the path |
| Opacity | `opacity` | 100 | 50 to 100, text, globe and buttons stay solid |
| Roundness | `cornerRadius` | 12 | 0 to 24 |
| Window outline | `outline` | off | edge in the accent color |
| Window tint | `surfaceTint` | 0 | how much accent goes over the background, 0 to 30 |
| Text size | `fontScale` | 100 | 80 to 150 |
| Spacing | `density` | `comfortable` | `compact`, `comfortable`, `spacious` |
</details>

<details>
<summary><b>Window</b>: panel or window, size</summary>
<br>
<p align="center"><img src="screenshots/settings-window.png" alt="Window settings" width="440"></p>

| Setting | Key | Default | |
| --- | --- | --- | --- |
| Open as | `openAs` | `panel` | `panel` (under the bar) or `window` (its own window), until you use **Pop out** / **Dock** |
| Width | `windowWidth` | 1180 | 800 to 1800, docked only (locked while popped out) |
| Height | `windowHeight` | 760 | 500 to 1200, docked only, never taller than the screen |
</details>

Settings are saved in `~/.local/state/omarchy-omatravel/settings.json`.

---

## Questions you might have

**A city has no pin.**
The lookup knows places with 1,000+ people. The city is still saved and listed,
it just doesn't know where to put it. Add `"lat"` and `"lng"` to its entry under
`city_meta` in `~/.local/share/omatravel/travel-data.json` and it shows up there.

**The globe is blank.**
It needs a working Qt shader backend. Rebuild the shaders with
`tools/build-shaders.sh` (needs `qt6-shadertools`).

**Follow Omarchy picked the wrong colors.**
If your shell tints or dims its own background, matching the theme by color can
miss, and it falls back to the shell's colors. The line under the theme buttons
says what it found.

**Where's my data?**
In `~/.local/share/omatravel/travel-data.json`, readable only by you. Exports go
to `~/.local/share/omatravel/exports/`, and only when you ask for one.

**Does it phone home?**
No. No network, no tracking. It only runs `sh` for small file jobs (folders,
saving, exporting), `cat`, `ls` and `find` to read your Omarchy theme, and
`wl-paste` when you press Ctrl+V in a text field (max 1 KB).

**I'm coming from 1.1.**
Anything you changed in the old Look tab is copied to the new settings once.
Your places are untouched.

**Something looks off on my setup.**
I've mostly tested it on my own machines, so open an issue with a screenshot.

## Under the hood

```
qml/
├── BarWidget.qml     the bar icon, tooltip and click actions
├── core/             TravelModel (state, saving, theme), SettingsStore
├── panel/            Panel, PanelFrame, DetachedWindow, SettingsView, SettingRow
├── globe/            GlobeView (shader, pins, arcs, labels)
├── controls/         FieldBox, FlatButton, SectionLabel
└── js/               Model.js (places, dates, stats, export), GlobeProjection.js
shaders/              the globe shader and its compiled .qsb
assets/earth.png      land, borders and grid lines
data/layers/          cities by zoom level + a name lookup
tools/                scripts that rebuild the three above
tests/                python3 tests/test_manifest.py
```

The globe is a fragment shader over a land/border/grid mask, tinted with your
theme. Pins, arcs and labels are drawn on a canvas on top with the same
projection. Cities are split into four bands by population, and a band is only
read from disk once you zoom in far enough to need it.

`assets/`, `shaders/*.qsb` and `data/layers/` come prebuilt, so installing needs
none of the tools. Those are only for rebuilding the data and are the one part
that downloads anything (Natural Earth and GeoNames). The plugin never runs them.

## Update or remove

```bash
omarchy plugin update io.github.qempexe.omatravel
omarchy restart shell        # don't skip this, the shell keeps the old version loaded
```

```bash
omarchy plugin remove io.github.qempexe.omatravel
omarchy restart shell
rm -rf ~/.local/share/omatravel ~/.local/state/omarchy-omatravel   # only if you want your map gone too
```

If the widget is still in `shell.json` after removing, delete its entry by hand.

## Credits and license

The code is [MIT](LICENSE). The bundled data keeps its own terms:

- **Cities** (`data/layers/`) come from [GeoNames](https://www.geonames.org)
  `cities1000`, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). I
  filtered them into zoom bands by population and kept only name, country code,
  population and rounded coordinates. Credit GeoNames if you reuse it.
- **Land, borders and lakes** (`assets/earth.png`) are rendered from
  [Natural Earth](https://www.naturalearthdata.com) 1:50m, public domain.
- **Flags** are emoji from your system font, nothing bundled.

Omatravel is an independent community plugin, not affiliated with or endorsed by
Omarchy or its authors.
