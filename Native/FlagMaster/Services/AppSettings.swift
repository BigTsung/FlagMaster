import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: Keys.language) } }
    @Published var musicVolume: VolumeLevel { didSet { defaults.set(musicVolume.rawValue, forKey: Keys.music) } }
    @Published var soundVolume: VolumeLevel { didSet { defaults.set(soundVolume.rawValue, forKey: Keys.sound) } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "zh-TW") ?? .traditionalChinese
        musicVolume = VolumeLevel(rawValue: defaults.string(forKey: Keys.music) ?? "medium") ?? .medium
        soundVolume = VolumeLevel(rawValue: defaults.string(forKey: Keys.sound) ?? "high") ?? .high
    }

    private enum Keys {
        static let language = "Language"
        static let music = "NativeMusicVolume"
        static let sound = "NativeSFXVolume"
    }
}
