import Foundation

enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case endless
    case timedChallenge
    case speedRound
    case twoLives
    case review

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.endless, .english): "Endless"
        case (.endless, .traditionalChinese): "無盡模式"
        case (.timedChallenge, .english): "Timed Challenge"
        case (.timedChallenge, .traditionalChinese): "限時挑戰"
        case (.speedRound, .english): "Speed Round"
        case (.speedRound, .traditionalChinese): "極速模式"
        case (.twoLives, .english): "Two Lives"
        case (.twoLives, .traditionalChinese): "兩次機會"
        case (.review, .english): "Spaced Review"
        case (.review, .traditionalChinese): "間隔複習"
        }
    }

    var symbol: String {
        switch self {
        case .endless: "infinity"
        case .timedChallenge: "timer"
        case .speedRound: "bolt.fill"
        case .twoLives: "heart.fill"
        case .review: "arrow.triangle.2.circlepath"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case traditionalChinese = "zh-TW"
    case english = "en"
    var id: String { rawValue }
}

enum VolumeLevel: String, CaseIterable, Identifiable, Sendable {
    case high, medium, low, off
    var id: String { rawValue }

    var value: Float {
        switch self { case .high: 1; case .medium: 0.6; case .low: 0.25; case .off: 0 }
    }
}
