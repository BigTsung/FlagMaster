# FlagMaster Native iOS

This directory is the maintained, native iOS version of FlagMaster. It replaces the Unity runtime with SwiftUI and Swift 6 while preserving the existing bundle identifier (`com.ChiuGa.FlagMasterApp`).

## Requirements

- Xcode 16 or newer
- iOS 17 or newer

Open `FlagMaster.xcodeproj`, select the `FlagMaster` scheme, choose an iPhone or iPad simulator, and Run.

Choose Traditional Chinese, English, Japanese, or Korean in Settings → Game → Language. The flag library searches country names in all four languages.

## Architecture

- `App`: application entry point
- `Models`: countries, modes, answer history models
- `Services`: JSON/resource loading, settings, persistent statistics
- `ViewModels`: game rules and countdown state
- `Views`: SwiftUI home, game, settings, and records screens
- `Resources`: the country JSON and 253 original flag images

The app has no third-party runtime dependencies. Answer history is written atomically to Application Support, while language and volume preferences use `UserDefaults`.

The native build includes background music, gameplay sound effects, and optional haptic feedback. See [the audio setup](Design/AUDIO.md) for asset mappings and local sound-pack installation.

## Game modes

- Endless: cycles through the full country list without repeating until needed
- Timed Challenge: answer as many questions as possible in 60 seconds
- Speed Round: 20 questions with 5 seconds per question
- Two Lives: ends after two incorrect answers
- Spaced Review: one pass through up to 50 flags whose review time has arrived
- Regional Journeys: up to 10 flags from Asia, Europe, Africa, North America, South America, or Oceania
- Similar Flags: compare a curated pair, reveal a concrete visual clue, then practice both flags

## Study cards

Open Collection → Study cards to browse a full-screen paper-style deck of the currently filtered flags. The study screen requests landscape before revealing the deck and restores the previous orientation when closed. A window that declines the request displays the landscape deck within the window. Cards retain their 1.7:1 aspect ratio and flags retain their original proportions. Tap the left/right half of a card, use the Previous/Next buttons, or swipe horizontally. Each move slides the cards past each other with a slight tilt; input is locked during the turn and navigation stops at either end. Cards show the localized country name, English name, and region. VoiceOver exposes named navigation actions. Reduce Motion and the animation preference disable the turn. Browsing does not change quiz statistics. The info button opens an information panel with the current country’s capital/seat, region, location map, national-flower field, flag introduction, and expandable sources. Closing returns to the same card, and navigation is blocked while the panel is open. All 198 entries include English and Traditional Chinese capital/flag information; 15 have sourced national-flower data, and missing flower data is explicitly identified. Japanese/Korean reference prose currently falls back to English. See [data coverage and sources](Design/Data/README.md).

Debug preview: `--preview-screen flashcards --preview-motion`. The iPhone lifecycle check `--preview-screen flags --preview-card-lifecycle` opens and closes the real full-screen deck and checks that the deck enters landscape and restores the previous orientation on close.

## Releasing a new version

1. Check the live version and latest uploaded build in App Store Connect before setting `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
2. Run the core tests, then exercise game modes, regional journeys, and flag comparisons in all four languages. Install the candidate over the last Unity release on an iPhone with existing history and verify the answer counts, language, and volume settings.
3. Archive with Product > Archive, validate in Organizer, and use TestFlight to verify the signed candidate on iPhone and iPad.
4. Prepare the store listing with the required iPhone and iPad screenshots, [Traditional Chinese release notes](Design/AppStore/whats-new.zh-Hant.txt), and the published privacy policy URL. Verify the App Privacy answers for the native release before submitting.

The old Unity folders at the repository root are retained only as migration reference. New product work should be made under `Native/`.

## Explorer interface and regression checks

See [the design and learning roadmap](Design/EXPERIENCE.md) for the new interface, fixed edge cases, validation limits, and proposed next steps.

Exploration, Regional Journeys, Similar Flags, and Spaced Review wait for **Continue journey** after an answer. Spaced Review runs through a snapshot of up to 50 due countries once. A correct due answer advances through 1, 3, 7, 14, and 30-day intervals; an incorrect answer returns in 10 minutes. Early practice records the answer without advancing the schedule. Results offer another pass through only that round's mistakes. Timed modes continue automatically. Backgrounding pauses the round.

The passport uses the 198 unique country entries in the JSON (the asset library also contains extra flags). Settings expose separate music and sound-effect volume, haptic feedback, and optional animation. On the first launch after a Unity upgrade, answer counts for countries in the current catalogue are imported from `Documents/CountryStats.json` when no native history exists. The language preference carries over, and Unity volume settings map to the nearest native level. The original Unity file stays on the device, and clearing history writes an empty native history so the old records stay cleared in the app.

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
