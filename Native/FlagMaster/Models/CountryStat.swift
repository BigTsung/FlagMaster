import Foundation

struct CountryStat: Codable, Identifiable, Sendable {
    let countryCode: String
    var correctAnswers: Int
    var totalAttempts: Int

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
