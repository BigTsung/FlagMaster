import SwiftUI

@main
struct FlagMasterApp: App {
    @UIApplicationDelegateAdaptor(FlagMasterAppDelegate.self) private var appDelegate
    @StateObject private var settings: AppSettings
    @StateObject private var stats: StatsStore

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--preview-screen") {
            // Isolate screenshot fixtures from the player's saved history and preferences.
            let preferences = AppSettings(defaults: UserDefaults(suiteName: "FlagMasterPreview.\(UUID())")!)
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--preview-japanese") { preferences.language = .japanese }
            else if arguments.contains("--preview-korean") { preferences.language = .korean }
            else if arguments.contains("--preview-english") { preferences.language = .english }
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
                .environment(\.locale, settings.language.locale)
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
            case "flashcards": NavigationStack { FlagFlashcardsView(countries: ((try? CountryRepository.load()) ?? []).sorted { $0.en < $1.en }) }
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


/// Restrict only the window that owns the study deck; other scenes keep their policy.
@MainActor
final class FlagMasterAppDelegate: NSObject, UIApplicationDelegate {
    static var landscapeScenes: Set<String> = []

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let scene = window?.windowScene,
           Self.landscapeScenes.contains(scene.session.persistentIdentifier) { return .landscape }
        return window?.traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }
}

struct FlashcardOrientation: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {}
    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) { controller.restore() }

    final class Controller: UIViewController {
        private weak var studyScene: UIWindowScene?
        private var originalOrientation: UIInterfaceOrientation = .unknown

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard studyScene == nil, let scene = view.window?.windowScene else { return }
            studyScene = scene
            originalOrientation = scene.interfaceOrientation
            FlagMasterAppDelegate.landscapeScenes.insert(scene.session.persistentIdentifier)
            update(scene, to: .landscape)
        }

        func restore() {
            guard let scene = studyScene else { return }
            studyScene = nil
            FlagMasterAppDelegate.landscapeScenes.remove(scene.session.persistentIdentifier)
            let mask: UIInterfaceOrientationMask
            if traitCollection.userInterfaceIdiom != .pad { mask = .portrait }
            else {
                switch originalOrientation {
                case .landscapeLeft: mask = .landscapeLeft
                case .landscapeRight: mask = .landscapeRight
                case .portraitUpsideDown: mask = .portraitUpsideDown
                default: mask = .portrait
                }
            }
            update(scene, to: mask)
        }

        private func update(_ scene: UIWindowScene, to mask: UIInterfaceOrientationMask) {
            for window in scene.windows {
                var controller = window.rootViewController
                while let current = controller {
                    current.setNeedsUpdateOfSupportedInterfaceOrientations()
                    controller = current.presentedViewController
                }
            }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { error in
                // Windowed iPad scenes can decline device-orientation requests.
                // The deck retains its landscape aspect ratio in that case.
                print("Study card orientation: \(error.localizedDescription)")
            }
        }
    }
}
