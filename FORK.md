# Fork notes (Côme Bruchet, 2026-10-13)

Personal fork of [krishhgg/Insomnia](https://github.com/krishhgg/Insomnia),
pinned on upstream `b6a7499c183b82eb30b5e969489e6a7420250eea` (main, 2026-10-13),
made after a full read of the repository for a MacBook Pro M5 on macOS 27.0.1.
Upstream docs apply unless this file says otherwise.

## Upstream pull requests merged here (open upstream at the time)

| PR | What | Why here |
|---|---|---|
| #108 | Backstop exits early between sessions (no lock, no `plutil`) | ~106 ms of CPU every minute saved |
| #102 | `defaults` wording of macOS 27 for an absent key | macOS 27 |
| #93 | Hold-to-end works on macOS 27; ring and pills follow the label colour | On macOS 27 a status item click lands at the item's centre, so the end control never saw a press (#60, #112) |
| #74 | "End session" in the right-click menu | A second way to end, independent of the gesture |
| #61 | A timer, battery or heat end with the lid closed puts the Mac to sleep (`IOPMSleepSystem`) | Upstream #94: `disablesleep 0` does not make macOS ask for the closed lid's sleep again, so the Mac ran until the lid opened |

## Changes of this fork

- **Closed-lid sleep is gated on the display list, not on
  `AppleClamshellCausesSleep`** (`ClosedLidSleep.swift`, `SessionManager.swift`).
  That key read `No` on this Mac with the lid open and no monitor, so a sleep
  gated on it would never have been asked. The sleep is asked when the lid is
  closed and `CGGetActiveDisplayList` lists no display other than the built-in
  panel; the key is logged for the record.
- **Battery floor while the app is gone** (`scripts/backstop.sh`). The recovery
  agent ends a valid session, as an expired one, when no Insomnia process runs
  and the Mac draws from its battery below config.json's `endFloor` (default
  10; 0 turns it off). Upstream only enforced the floor while the app ran.
  Heat is not read: the thermal state is not readable from a shell without
  root.
- **Closed-lid sleep from the recovery agent** (`scripts/backstop.sh`). After a
  session the agent ended by its deadline or by the battery floor, `pmset
  sleepnow` when `ioreg` says the lid is closed and `system_profiler` lists no
  external display. Never after `--force` (install.sh and uninstall.sh).
- **Digits by key code** (`DurationInput.digit(keyCode:characters:)`,
  `StatusItemController.handleKey`). The pills read the digit row and the
  keypad by key code. Upstream read the typed character, so on a French AZERTY
  layout a bare press of the top row (`& é " ' ( § è ! ç à`) was swallowed in
  silence and Enter on empty pills started the 4-hour default. The letters
  d/h/m and everything else still go by character. Test: `DurationKeyTests.swift`.
- Tests for both script changes in `RecoveryScriptTests.swift` (fakes for
  `pmset -g batt`, `pmset sleepnow`, `ioreg`, `system_profiler`).
- Install-time configuration, not code: `freezeList` emptied in config.json, so
  no app is frozen (SIGSTOP) at lid close.

## Not changed, by choice

- Clamshell mode on an external display (upstream #97): this Mac has none.
- Notarization: a locally built app has no quarantine flag, so Gatekeeper does
  not block it; a Developer ID is not worth 99 USD a year for one Mac.

## Building

This Mac has the Command Line Tools only, and they ship no SwiftUI macro
plugin (`plugin for module 'SwiftUIMacros' not found`), so `swift build` fails
here as it would for any SwiftUI app. Builds run on GitHub Actions in the fork
[comebruchet-cpu/Insomnia](https://github.com/comebruchet-cpu/Insomnia):
`gh workflow run release.yml -R comebruchet-cpu/Insomnia --ref main -f nightly=true`
tests on macos-26, builds, and publishes an attested nightly prerelease. Verify
and install from the zip as upstream's docs/install.md describes, with
`-R comebruchet-cpu/Insomnia` in the attestation command.
