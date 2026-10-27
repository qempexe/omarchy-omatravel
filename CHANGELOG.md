# Changelog

All notable changes to Omatravel. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [1.3.0] - 2026-10-27

### Added

- **Globe side**: the globe can sit on the right, with your lists on the left.
- **Outline gradient** and **Outline color**: the window outline can run through your
  theme's window border gradient, at its angle, or take one of its colors.
- An **About** tab with the logo, the version and a link to more plugins, and the logo
  in the atlas's header.
- Settings search: on the Settings tab the header's search box looks through every
  setting. **Changed only** lists what differs from the defaults.

### Changed

- The settings are split into tabs (Bar, Globe, Look, Window, About), with sections
  inside Look. Settings that do nothing with your current choices are dimmed instead
  of hidden.
- The globe stays smooth when zoomed in: only the places in view are looked at, and
  their names are drawn on the GPU.
- The README follows a new layout, with new screenshots.

### Fixed

- The outline of the docked atlas sits exactly on the edge of its background at every
  size, roundness and scale.
- Theme files are read 64 KB at a time at most.
- Text stays readable on a light background, even with a light text color: it is made
  darker, keeping its tint, only as much as needed. The logo switches to its dark
  version there.

## [1.2.1] - 2026-10-15

### Changed

- The QML is organised into core, panel, globe, controls and js folders.
- Places are read and saved more strictly.
- New README, screenshots and preview.

## [1.2.0] - 2026-10-13

### Added

- A Settings tab inside the atlas, with new options, saved on their own.
- The settings are declared in the manifest, with tests.

### Changed

- A new bordered popup panel with restyled visuals.

### Fixed

- Dock no longer closes everything when no other window is open.

## [1.1.0] - 2026-10-08

### Added

- Stats, time travel, checking off wishlist places, and export to CSV or JSON.

## [1.0.0] - 2026-10-03

### Added

- First release: an interactive globe widget for the Omarchy bar.

[1.3.0]: https://github.com/qempexe/omarchy-omatravel/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/qempexe/omarchy-omatravel/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/qempexe/omarchy-omatravel/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/qempexe/omarchy-omatravel/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/qempexe/omarchy-omatravel/releases/tag/v1.0.0
