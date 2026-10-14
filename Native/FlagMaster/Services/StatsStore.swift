import Foundation
import Combine

@MainActor
final class StatsStore: ObservableObject {
    @Published private(set) var stats: [String: CountryStat] = [:]
    private let fileURL: URL

    init(fileManager: FileManager = .default, fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
            load()
            return
        }
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("FlagMaster", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("country-stats.json")
        load()
    }

    func record(_ country: Country, correct: Bool, at date: Date = Date()) {
        var value = stats[country.abb2] ?? CountryStat(countryCode: country.abb2, correctAnswers: 0, totalAttempts: 0)
        value.totalAttempts += 1
        if correct { value.correctAnswers += 1 }
        let isDue = value.nextReviewAt.map { $0 <= date } ?? true
        if !correct {
            value.reviewStage = 0
            value.nextReviewAt = date.addingTimeInterval(10 * 60)
        } else if isDue {
            let stage = min(5, max(0, value.reviewStage ?? 0) + 1)
            value.reviewStage = stage
            let days = [1, 3, 7, 14, 30][stage - 1]
            value.nextReviewAt = date.addingTimeInterval(Double(days) * 86_400)
        }
        // Early practice is recorded but cannot inflate the spaced-review stage.
        value.lastReviewedAt = date
        stats[country.abb2] = value
        save()
    }

    func weakestCountryCodes(limit: Int = 50) -> [String] {
        stats.values
            .filter { $0.needsPractice }
            .sorted {
                if $0.accuracy == $1.accuracy { if $0.totalAttempts == $1.totalAttempts { return $0.countryCode < $1.countryCode }
                    return $0.totalAttempts > $1.totalAttempts }
                return $0.accuracy < $1.accuracy
            }
            .prefix(limit)
            .map(\.countryCode)
    }

    func dueCountryCodes(at date: Date = Date(), limit: Int = 50) -> [String] {
        stats.values.filter { $0.totalAttempts > 0 && ($0.nextReviewAt ?? .distantPast) <= date }
            .sorted {
                let left = $0.nextReviewAt ?? .distantPast
                let right = $1.nextReviewAt ?? .distantPast
                return left == right ? $0.countryCode < $1.countryCode : left < right
            }.prefix(max(0, limit)).map(\.countryCode)
    }

    var nextReviewDate: Date? { stats.values.compactMap(\.nextReviewAt).min() }
    var attempts: Int { stats.values.reduce(0) { $0 + $1.totalAttempts } }
    var correct: Int { stats.values.reduce(0) { $0 + $1.correctAnswers } }
    var accuracy: Double { attempts == 0 ? 0 : Double(correct) / Double(attempts) }
    var mastered: Int { stats.values.filter(\.isMastered).count }

    func clear() {
        stats = [:]
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let values = try? JSONDecoder().decode([CountryStat].self, from: data) else { return }
        stats = Dictionary(values.filter { $0.totalAttempts >= 0 && $0.correctAnswers >= 0 && $0.correctAnswers <= $0.totalAttempts }.map { ($0.countryCode, $0) }, uniquingKeysWith: { _, latest in latest })
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(Array(stats.values)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
