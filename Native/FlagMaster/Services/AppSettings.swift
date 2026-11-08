import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: Keys.language) } }
    @Published var musicVolume: VolumeLevel { didSet { defaults.set(musicVolume.rawValue, forKey: Keys.music) } }
    @Published var soundVolume: VolumeLevel { didSet { defaults.set(soundVolume.rawValue, forKey: Keys.sound) } }
    @Published var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) } }

    @Published var animatedEffects: Bool { didSet { defaults.set(animatedEffects, forKey: "AnimatedEffects") } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        animatedEffects = defaults.object(forKey: "AnimatedEffects") as? Bool ?? true
        let bundleLanguage = Bundle.main.preferredLocalizations.first.flatMap(AppLanguage.init(rawValue:))
        let defaultLanguage: AppLanguage = switch bundleLanguage {
        case .japanese: .japanese
        case .korean: .korean
        default: .traditionalChinese
        }
        language = defaults.string(forKey: Keys.language).flatMap(AppLanguage.init(rawValue:)) ?? defaultLanguage
        musicVolume = Self.volume(defaults, nativeKey: Keys.music, legacyKey: "MusicVolume", fallback: .medium)
        soundVolume = Self.volume(defaults, nativeKey: Keys.sound, legacyKey: "SFXVolume", fallback: .high)
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
    }

    private static func volume(
        _ defaults: UserDefaults, nativeKey: String, legacyKey: String, fallback: VolumeLevel
    ) -> VolumeLevel {
        if let value = defaults.string(forKey: nativeKey).flatMap(VolumeLevel.init(rawValue:)) {
            return value
        }
        guard let legacy = defaults.object(forKey: legacyKey) as? NSNumber else { return fallback }
        return VolumeLevel.allCases.min {
            abs($0.value - legacy.floatValue) < abs($1.value - legacy.floatValue)
        } ?? fallback
    }

    private enum Keys {
        static let language = "Language"
        static let music = "NativeMusicVolume"
        static let sound = "NativeSFXVolume"
        static let haptics = "NativeHapticsEnabled"
    }
}
