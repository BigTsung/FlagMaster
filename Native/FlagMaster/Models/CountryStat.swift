import Foundation

struct CountryStat: Codable, Identifiable, Sendable {
    let countryCode: String
    var correctAnswers: Int
    var totalAttempts: Int

    // Optional fields preserve decoding of pre-scheduling answer history.
    var lastReviewedAt: Date? = nil
    var nextReviewAt: Date? = nil
    var reviewStage: Int? = nil

    var isMastered: Bool { (reviewStage ?? 0) >= 3 }
    var needsPractice: Bool { totalAttempts > correctAnswers && !isMastered }
    var id: String { countryCode }
    var accuracy: Double {
        totalAttempts == 0 ? 0 : Double(correctAnswers) / Double(totalAttempts)
    }
}

struct WrongAnswer: Identifiable, Sendable {
    let id = UUID()
    let country: Country
    let selected: Country?
}
