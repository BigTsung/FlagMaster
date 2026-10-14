# FlagMaster Native iOS

This directory is the maintained, native iOS version of FlagMaster. It replaces the Unity runtime with SwiftUI and Swift 6 while preserving the existing bundle identifier (`com.ChiuGa.FlagMasterApp`).

## Requirements

- Xcode 16 or newer
- iOS 17 or newer

Open `FlagMaster.xcodeproj`, select the `FlagMaster` scheme, choose an iPhone or iPad simulator, and Run.

## Architecture

- `App`: application entry point
- `Models`: countries, modes, answer history models
- `Services`: JSON/resource loading, settings, persistent statistics
- `ViewModels`: game rules and countdown state
- `Views`: SwiftUI home, game, settings, and records screens
- `Resources`: the country JSON and 253 original flag images

The app has no third-party runtime dependencies. Answer history is written atomically to Application Support, while language and volume preferences use `UserDefaults`.

The Unity repository did not contain the referenced BGM/SFX media files. The native build therefore uses iOS haptic success/error feedback (respecting the Haptic Feedback setting). Add licensed audio assets before enabling background music in a release.

## Game modes

- Endless: cycles through the full country list without repeating until needed
- Timed Challenge: answer as many questions as possible in 60 seconds
- Speed Round: 20 questions with 5 seconds per question
- Two Lives: ends after two incorrect answers
- Spaced Review: one pass through up to 50 flags whose review time has arrived
- Regional Journeys: up to 10 flags from Asia, Europe, Africa, North America, South America, or Oceania
- Similar Flags: compare a curated pair, reveal a concrete visual clue, then practice both flags

## Releasing a new version

1. Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the target Build Settings.
2. Run a simulator build and test all five modes in both languages.
3. Set the Apple Developer Team under Signing & Capabilities.
4. Archive with Product > Archive and validate it in Organizer.

The old Unity folders at the repository root are retained only as migration reference. New product work should be made under `Native/`.

## Explorer interface and regression checks

See [the design and learning roadmap](Design/EXPERIENCE.md) for the new interface, fixed edge cases, validation limits, and proposed next steps.

Exploration, Regional Journeys, Similar Flags, and Spaced Review wait for **Continue journey** after an answer. Spaced Review runs through a snapshot of up to 50 due countries once. A correct due answer advances through 1, 3, 7, 14, and 30-day intervals; an incorrect answer returns in 10 minutes. Early practice records the answer without advancing the schedule. Results offer another pass through only that round's mistakes. Timed modes continue automatically. Backgrounding pauses the round.

The passport uses the 198 unique country entries in the JSON (the asset library also contains extra flags). Music controls are hidden until licensed audio exists; the settings screen exposes haptic feedback and optional animation instead. Preferences and statistics remain backward compatible.

Run deterministic core tests on macOS:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test --package-path Native --scratch-path /tmp/FlagMaster-tests
```

Build the app:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Native/FlagMaster.xcodeproj -scheme FlagMaster -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/FlagMaster-build CODE_SIGNING_ALLOWED=NO build
```

Debug builds support isolated screenshot fixtures through launch arguments: `--preview-screen home|game|records|settings|journeys|comparisons|region-game|comparison-game|review`, optionally `--preview-english`, `--preview-paused`, `--preview-answer`, `--preview-result`, or `--preview-revealed`. These routes are excluded from Release builds and use separate temporary statistics/preferences. Launch without arguments to return to the normal app.

See [the implemented learning features](Design/LEARNING.md) for scheduling behavior, regional classification, comparison sources, validation, and known limits.
