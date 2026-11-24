import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: Keys.language) } }
    @Published var musicVolume: VolumeLevel { didSet { defaults.set(musicVolume.rawValue, forKey: Keys.music) } }
    @Published var soundVolume: VolumeLevel { didSet { defaults.set(soundVolume.rawValue, forKey: Keys.sound) } }
    @Published var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) } }

    @Published var animatedEffects: Bool { didSet { defaults.set(animatedEffects, forKey: "AnimatedEffects") } }

    /// Last day (yyyy-MM-dd, local calendar) a daily session was completed, and the run of days ending there.
    @Published private(set) var lastDailyPractice: String? { didSet { defaults.set(lastDailyPractice, forKey: Keys.lastDaily) } }
    @Published private(set) var dailyStreakCount: Int { didSet { defaults.set(dailyStreakCount, forKey: Keys.dailyStreak) } }
    @Published private(set) var bestQuizScore: Int? { didSet { defaults.set(bestQuizScore, forKey: Keys.bestQuiz) } }

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
        lastDailyPractice = defaults.string(forKey: Keys.lastDaily)
        dailyStreakCount = defaults.integer(forKey: Keys.dailyStreak)
        bestQuizScore = defaults.object(forKey: Keys.bestQuiz) as? Int
    }

    private static func dayKey(_ date: Date, _ calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    func practicedToday(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        lastDailyPractice == Self.dayKey(now, calendar)
    }

    /// The streak still counts until the end of the day after the last session.
    func dailyStreak(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let last = lastDailyPractice else { return 0 }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        return last == Self.dayKey(now, calendar) || last == Self.dayKey(yesterday, calendar) ? dailyStreakCount : 0
    }

    func recordDailyPractice(now: Date = Date(), calendar: Calendar = .current) {
        guard !practicedToday(now: now, calendar: calendar) else { return }
        dailyStreakCount = dailyStreak(now: now, calendar: calendar) + 1
        lastDailyPractice = Self.dayKey(now, calendar)
    }

    /// Returns true when the score is a new personal best.
    @discardableResult
    func recordQuizScore(_ score: Int) -> Bool {
        guard score > (bestQuizScore ?? -1) else { return false }
        bestQuizScore = score
        return true
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
        static let lastDaily = "NativeLastDailyPractice"
        static let dailyStreak = "NativeDailyStreak"
        static let bestQuiz = "NativeBestQuizScore"
    }
}
