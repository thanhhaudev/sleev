# sleev

A macOS menubar utility that tucks away icons behind a compact sleeve handle.
Inspired by Hidden Bar, modernized for macOS 14+.

## Status

Pre-alpha. Phase 1 (M0–M3) covers the foundation + Hidden-Bar-parity feature set.

## Build

Requires Xcode 15.4+, macOS 14+, and these tools:

```bash
brew install xcodegen swiftlint swiftformat
xcodegen generate
xcodebuild -scheme Sleev -configuration Debug build
```

## License

MIT. See `LICENSE`.
