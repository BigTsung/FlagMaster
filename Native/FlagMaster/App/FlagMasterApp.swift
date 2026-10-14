import SwiftUI

@main
struct FlagMasterApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var stats: StatsStore

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--preview-screen") {
            // Isolate screenshot fixtures from the player's saved history and preferences.
            let preferences = AppSettings(defaults: UserDefaults(suiteName: "FlagMasterPreview.\(UUID())")!)
            preferences.language = ProcessInfo.processInfo.arguments.contains("--preview-english") ? .english : .traditionalChinese
            preferences.animatedEffects = ProcessInfo.processInfo.arguments.contains("--preview-motion")
            preferences.musicVolume = .off
            preferences.soundVolume = .off
            preferences.hapticsEnabled = false
            let store = StatsStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("preview-\(UUID()).json"))
            if let countries = try? CountryRepository.load() {
                for country in countries.prefix(5) { store.record(country, correct: true); store.record(country, correct: false, at: Date().addingTimeInterval(-700)) }
            }
            _settings = StateObject(wrappedValue: preferences)
            _stats = StateObject(wrappedValue: store)
            return
        }
        #endif
        _settings = StateObject(wrappedValue: AppSettings())
        _stats = StateObject(wrappedValue: StatsStore())
    }

    var body: some Scene {
        WindowGroup {
            content.environmentObject(settings).environmentObject(stats).preferredColorScheme(.dark)
                .environment(\.locale, Locale(identifier: settings.language.rawValue))
        }
    }

    @ViewBuilder private var content: some View {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "--preview-screen"), args.indices.contains(index + 1) {
            switch args[index + 1] {
            case "journeys": NavigationStack { JourneyPickerView { _ in } }
            case "comparisons": NavigationStack { ComparisonLibraryView { _ in } }
            case "flags": NavigationStack { FlagLibraryView() }
            case "region-game": ZStack { AppBackground(); GameView(mode: .endless, stats: stats, settings: settings, practice: .region(.asia)) {} }
            case "comparison-game": ZStack { AppBackground(); GameView(mode: .endless, stats: stats, settings: settings, practice: .comparison(FlagComparison.all[0])) {} }
            case "review": ZStack { AppBackground(); GameView(mode: .review, stats: stats, settings: settings) {} }
            case "settings": NavigationStack { SettingsView() }
            case "records": NavigationStack { RecordsView() }
            case "game": ZStack { AppBackground(); GameView(mode: .endless, stats: stats, settings: settings) {} }
            default: RootView()
            }
        } else { RootView() }
        #else
        RootView()
        #endif
    }
}
