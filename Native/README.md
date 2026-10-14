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

The Unity repository did not contain the referenced BGM/SFX media files. The native build therefore uses iOS haptic success/error feedback (respecting the Sound Effects Off setting). Add licensed audio assets before enabling background music in a release.

## Game modes

- Endless: cycles through the full country list without repeating until needed
- Timed Challenge: answer as many questions as possible in 60 seconds
- Speed Round: 20 questions with 5 seconds per question
- Two Lives: ends after two incorrect answers
- Review: samples from the 50 lowest-accuracy countries in saved history

## Releasing a new version

1. Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the target Build Settings.
2. Run a simulator build and test all five modes in both languages.
3. Set the Apple Developer Team under Signing & Capabilities.
4. Archive with Product > Archive and validate it in Organizer.

The old Unity folders at the repository root are retained only as migration reference. New product work should be made under `Native/`.
