import Foundation

enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case endless
    case timedChallenge
    case speedRound
    case twoLives
    case review

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .endless: language.text("Endless", "無盡模式", ja: "エンドレス", ko: "무한 모드")
        case .timedChallenge: language.text("Timed Challenge", "限時挑戰", ja: "タイムチャレンジ", ko: "시간 도전")
        case .speedRound: language.text("Speed Round", "極速模式", ja: "スピードラウンド", ko: "스피드 라운드")
        case .twoLives: language.text("Two Lives", "兩次機會", ja: "ライフ 2 つ", ko: "기회 두 번")
        case .review: language.text("Spaced Review", "間隔複習", ja: "間隔復習", ko: "간격 복습")
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
    case japanese = "ja"
    case korean = "ko"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }

    var displayName: String {
        text("English", "繁體中文", ja: "日本語", ko: "한국어")
    }

    func text(_ english: String, _ traditionalChinese: String, ja: String, ko: String) -> String {
        switch self {
        case .english: english
        case .traditionalChinese: traditionalChinese
        case .japanese: ja
        case .korean: ko
        }
    }
}

enum VolumeLevel: String, CaseIterable, Identifiable, Sendable {
    case high, medium, low, off
    var id: String { rawValue }

    var value: Float {
        switch self { case .high: 1; case .medium: 0.6; case .low: 0.25; case .off: 0 }
    }
}

// Semantic cues are emitted by game rules; playback stays in the UI/audio layer.
enum SoundEffect: String, CaseIterable, Sendable {
    case tap = "sfx_tap"
    case correct = "sfx_correct"
    case wrong = "sfx_wrong"
    case timeout = "sfx_timeout"
    case countdown = "sfx_countdown"
    case complete = "sfx_complete"
    case end = "sfx_end"
    case gameOver = "sfx_game_over"

    var priority: Int {
        switch self {
        case .tap, .countdown: 0
        case .correct, .wrong, .timeout: 1
        case .complete, .end, .gameOver: 2
        }
    }
}

struct GameSoundEvent: Equatable {
    let id: Int
    let effect: SoundEffect
}
