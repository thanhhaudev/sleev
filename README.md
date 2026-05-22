# sleev

A macOS menu bar utility that tucks icons away behind a compact sleeve
handle — a modern take on Hidden Bar.

## Features

- Tuck menu bar icons away behind a compact sleeve handle.
- Toggle the sleeve by clicking the handle or with a global keyboard
  shortcut.
- A popover that lists every menu bar item across two zones — sleeved and
  in the menu bar.
- Drag items between zones, or rearrange them directly in the menu bar.
- An auto-hide timer that re-tucks the icons after a spell of inactivity.
- Launch at login.
- A customizable separator — adjust its size and opacity.
- A short onboarding flow that walks through granting permission.

## Requirements

macOS 26 or later.

## Install

1. Download `Sleev-1.0.0.dmg` from the
   [latest release](https://github.com/thanhhaudev/sleev/releases/latest).
2. Open the DMG and drag **sleev** into Applications.
3. sleev is not notarized, so macOS will not open it from a double-click
   the first time. Right-click the app in Applications, choose **Open**,
   then confirm. This is needed only once.
4. Grant Accessibility permission when prompted — sleev needs it to read
   and rearrange menu bar items.

## Permissions & privacy

sleev needs Accessibility permission to see the menu bar and move its
icons. It runs entirely on the Mac and sends nothing over the network.

## Build from source

Requires macOS 26 and Xcode 26.x, plus:

```bash
brew install xcodegen swiftlint swiftformat
make build      # build the app
make ci         # lint, build, and run the tests
```

## License

MIT. See [LICENSE](LICENSE).
