# sleev — Phase 1 manual test plan

Run after every Phase 1 release candidate (every push to `master` that ships an `.app`).

## Environment

- macOS 14.x or newer
- sleev installed at `/Applications/Sleev.app`
- Reset state before starting:
  ```bash
  pkill -x Sleev 2>/dev/null || true
  pkill -x SleevAgent 2>/dev/null || true
  tccutil reset Accessibility dev.sleev.Sleev.Agent
  launchctl bootout gui/$(id -u)/dev.sleev.Sleev.Agent 2>/dev/null || true
  defaults delete group.dev.sleev 2>/dev/null || true
  ```

## 1. First launch & permission prompt

1. Double-click `Sleev.app` (or `make run`).
2. Expected: onboarding window appears titled "sleev needs Accessibility access".
3. Click **Open System Settings**.
4. Expected: System Settings opens at Privacy & Security → Accessibility. sleev's entry (the agent) is listed.
5. Toggle sleev on.
6. Expected: within 1–2 s the onboarding window disappears; two status items appear in the menubar.

## 2. Sleeve handle layout persistence

1. ⌘+drag the chevron so it sits between Wi-Fi and the clock.
2. ⌘+drag the (invisible) separator so it sits immediately left of the chevron.
3. Right-click chevron → Quit sleev. Relaunch.
4. Expected: both items return to the same positions (`autosaveName` restored).

## 3. Toggle collapse/expand

1. Click the chevron.
2. Expected: every menubar icon between separator and chevron disappears.
3. Click again.
4. Expected: icons reappear; chevron triangle flips (left ↔ right) with a smooth Y-axis animation.

## 4. Auto-hide

1. Right-click chevron → confirm "Disable Auto Collapse" is shown (means auto-hide is currently ON).
2. Lower the delay for testing:
   ```bash
   defaults write group.dev.sleev sleev.preferences.autoHide.delaySeconds -float 3.0
   ```
   then quit/relaunch sleev.
3. Expand the menubar.
4. Expected: within ~3 s of no interaction, items collapse automatically.
5. Restore:
   ```bash
   defaults delete group.dev.sleev sleev.preferences.autoHide.delaySeconds
   ```

## 5. Auto-hide toggle off

1. Right-click chevron → "Disable Auto Collapse".
2. Expand and wait > 10 s.
3. Expected: items remain visible.
4. Right-click → "Enable Auto Collapse" to restore.

## 6. Permission revoke at runtime

1. With sleev running and status items installed, open System Settings → Privacy & Security → Accessibility.
2. Toggle sleev off.
3. Expected: within 1–2 s, status items disappear; onboarding window reappears.
4. Toggle sleev back on.
5. Expected: status items return.

## 7. Quit cleanup

1. Right-click chevron → "Quit sleev".
2. Wait ~5 s, then check:
   ```bash
   pgrep -x Sleev && pgrep -x SleevAgent
   ```
3. Expected: neither process is running.

## 8. Screen change

1. Plug in an external display (or change main display resolution).
2. Expected: chevron continues to collapse correctly; no icons leak in from off-screen.

## 9. Reboot persistence

1. Reboot the Mac.
2. Expected: sleev does NOT autostart yet (autostart lands in a later phase).
3. Launch manually.
4. Expected: previous handle/separator positions restored.

## Sign-off

| # | Test | Pass/Fail | Notes |
|---|---|---|---|
| 1 | First launch & permission prompt | | Pending Hau |
| 2 | Layout persistence | | Pending Hau |
| 3 | Toggle collapse/expand | | Pending Hau |
| 4 | Auto-hide enabled (3s) | | Pending Hau |
| 5 | Auto-hide disabled | | Pending Hau |
| 6 | Runtime revoke | | Pending Hau |
| 7 | Quit cleanup | | Partial: `Sleev` exits; `SleevAgent` lingers under `KeepAlive` when killed via `pkill` (bypasses XPC quit signal). Full UI quit path (right-click → Quit) requires human verification. Pending Hau |
| 8 | Screen change | | Pending Hau |
| 9 | Reboot persistence | | Pending Hau |
