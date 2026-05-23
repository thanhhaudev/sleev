# Changelog

All notable changes to sleev are documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-05-24

### Changed

- New tagline in the About panel and README: "One click hides half the
  menu bar. Another brings it back."
- README now walks through granting Accessibility permission in System
  Settings, documents the ⌘-drag gesture for repositioning the handle
  and separator, and includes a demo GIF.

### Fixed

- v1.0.0 failed to launch on any Mac outside the maintainer's. It was
  signed with an Apple Development certificate (which macOS Gatekeeper
  rejects for distribution) and declared a team ID the maintainer does
  not own. v1.0.1 ships ad-hoc-signed; install via Homebrew Cask, or via
  direct DMG plus `xattr -cr /Applications/Sleev.app` (see README).
- Removed an unused App Groups entitlement that compounded the launch
  failure on machines outside the maintainer's provisioning profile.

### Changed

- Contributors can now build the repo with `make ci` without an Apple
  Developer account — the project signs ad-hoc by default.

## [1.0.0] - 2026-05-22

### Added

- Sleeve handle that tucks menu bar icons away and brings them back.
- Global keyboard shortcut to toggle the sleeve.
- Popover listing every menu bar item across two zones — sleeved and in
  the menu bar.
- Drag items between zones in the popover, with reconciliation against
  manual rearrangement in the menu bar.
- Auto-hide timer that re-tucks the icons after inactivity.
- Launch at login.
- Customizable separator size and opacity.
- Onboarding flow with Accessibility permission setup.
