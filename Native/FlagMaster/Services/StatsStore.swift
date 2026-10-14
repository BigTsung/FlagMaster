import Foundation

@MainActor
final class StatsStore: ObservableObject {
    @Published private(set) var stats: [String: CountryStat] = [:]
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("FlagMaster", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("country-stats.json")
        load()
    }

    func record(_ country: Country, correct: Bool) {
        var value = stats[country.abb2] ?? CountryStat(countryCode: country.abb2, correctAnswers: 0, totalAttempts: 0)
        value.totalAttempts += 1
        if correct { value.correctAnswers += 1 }
        stats[country.abb2] = value
        save()
    }

    func weakestCountryCodes(limit: Int = 50) -> [String] {
        stats.values
            .filter { $0.totalAttempts > 0 }
            .sorted {
                if $0.accuracy == $1.accuracy { return $0.totalAttempts > $1.totalAttempts }
                return $0.accuracy < $1.accuracy
            }
            .prefix(limit)
            .map(\.countryCode)
    }

    func clear() {
        stats = [:]
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let values = try? JSONDecoder().decode([CountryStat].self, from: data) else { return }
        stats = Dictionary(uniqueKeysWithValues: values.map { ($0.countryCode, $0) })
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(Array(stats.values)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
