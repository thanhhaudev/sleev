# sleev

Hides the menu bar icons nobody clicks.

## Requirements

macOS 26 or later.

## Install

1. Download `Sleev-<version>.dmg` from the
   [latest release](https://github.com/thanhhaudev/sleev/releases/latest).
2. Open the DMG and drag **sleev** into Applications.
3. sleev is signed ad-hoc, not with an Apple Developer ID, so macOS
   refuses to open it after download. Clear the quarantine attribute:

   ```bash
   xattr -cr /Applications/Sleev.app
   ```

4. Open sleev from Applications. Grant Accessibility permission when
   prompted — without it, sleev can neither see the menu bar nor move
   anything in it.

### Homebrew Cask (coming soon)

A Cask formula is pending submission to homebrew/homebrew-cask. Once
merged, `brew install --cask sleev` will handle step 3 above
automatically.

## How to use it

The popover lists every menu bar item in two zones — sleeved and visible.

| Action | What it does |
| --- | --- |
| Click the handle, or press the global shortcut | Hides or shows the sleeved icons |
| Drag an item in the popover | Moves it between the sleeved and visible zones |
| Drag icons in the menu bar | Rearranges them as usual; sleev keeps up |
| Leave it alone for a while | Auto-hide re-tucks the icons |

Open **Settings** for the global shortcut, launch at login, and the
separator's size and opacity.

## Permissions & privacy

sleev needs Accessibility permission, and nothing else. It runs entirely
on the Mac and never touches the network.

## Build from source

Requires macOS 26 and Xcode 26.x.

```bash
brew install xcodegen swiftlint swiftformat
make build      # build the app
make ci         # lint, build, and test
```

## Credits

sleev's menu bar approach is derived from
[Hidden Bar](https://github.com/dwarvesf/hidden) by Dwarves Foundation.
