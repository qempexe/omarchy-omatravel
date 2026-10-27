# Contributing

Thanks for wanting to help. Bug reports and ideas go in the
[issues](https://github.com/qempexe/omarchy-omatravel/issues); a screenshot and your
Omarchy version help a lot.

## Working on it

Clone it into your plugins folder and restart the shell after every change:

```bash
omarchy plugin add https://github.com/qempexe/omarchy-omatravel.git --enable --yes
cd ~/.config/omarchy/plugins/io.github.qempexe.omatravel
omarchy restart shell
```

Where things live is in the README, under **Under the hood**. A few rules the code
keeps to:

- **Every setting is defined once**, in `qml/js/Schema.js`. The settings tab, the bar
  widget and the model read it from there. Add a setting there, then the same entry to
  `manifest.json`; the test checks the two agree.
- **No native text inputs** (`TextInput`, `TextField`, ...): text fields are
  `SettingRow`'s and `FieldBox`, and pasting reads at most 1 KB.
- **Every `Text` shows plain text** (`textFormat: Text.PlainText`). Place, profile and
  theme names are never read as markup.
- **Your data never goes on a command line.** Saves and exports go through stdin to an
  owner-only file.
- **No network.** The plugin works offline; only the scripts in `tools/` download
  anything, and the plugin never runs them.

## Tests

```bash
python3 tests/test_manifest.py   # settings, manifest and files agree, plain text, no native inputs
node tests/test_globe.js         # the globe never leaves out a place that is on screen
```

Run both before you open a pull request.

## Commits

[Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `perf:`,
`refactor:`, `docs:`, `test:`, `chore:`, one small change each, with a one-line
message that says what the change does.
