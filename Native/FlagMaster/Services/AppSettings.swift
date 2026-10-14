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
        language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "zh-TW") ?? .traditionalChinese
        musicVolume = VolumeLevel(rawValue: defaults.string(forKey: Keys.music) ?? "medium") ?? .medium
        soundVolume = VolumeLevel(rawValue: defaults.string(forKey: Keys.sound) ?? "high") ?? .high
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
    }

    private enum Keys {
        static let language = "Language"
        static let music = "NativeMusicVolume"
        static let sound = "NativeSFXVolume"
        static let haptics = "NativeHapticsEnabled"
    }
}
