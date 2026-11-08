import Foundation
import Combine

@MainActor
final class StatsStore: ObservableObject {
    @Published private(set) var stats: [String: CountryStat] = [:]
    private let fileURL: URL

    init(
        fileManager: FileManager = .default,
        fileURL: URL? = nil,
        legacyFileURL: URL? = nil,
        legacyCountries: [Country]? = nil
    ) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let directory = base.appendingPathComponent("FlagMaster", isDirectory: true)
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            self.fileURL = directory.appendingPathComponent("country-stats.json")
        }
        load()
        guard !fileManager.fileExists(atPath: self.fileURL.path) else { return }
        let source = legacyFileURL ?? (fileURL == nil
            ? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("CountryStats.json")
            : nil)
        if let source, fileManager.fileExists(atPath: source.path),
           let countries = legacyCountries ?? (try? CountryRepository.load()) {
            migrateLegacyStats(from: source, countries: countries)
        }
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
        save()
    }

    private struct LegacyStats: Decodable {
        struct Entry: Decodable {
            let countryName: String
            let correctAnswers: Int32
            let totalAttempts: Int32
        }

        let statsList: [Entry]
    }

    private func migrateLegacyStats(from source: URL, countries: [Country]) {
        guard let data = try? Data(contentsOf: source),
              let legacy = try? JSONDecoder().decode(LegacyStats.self, from: data) else { return }

        let codes = Set(countries.map(\.abb2))
        let codesByName = Dictionary(countries.map { ($0.cn, $0.abb2) }, uniquingKeysWith: { first, _ in first })
        for entry in legacy.statsList {
            guard let code = Self.legacyCountryCodes[entry.countryName] ?? codesByName[entry.countryName],
                  codes.contains(code),
                  entry.totalAttempts > 0,
                  entry.correctAnswers >= 0,
                  entry.correctAnswers <= entry.totalAttempts else { continue }
            var stat = stats[code] ?? CountryStat(countryCode: code, correctAnswers: 0, totalAttempts: 0)
            stat.correctAnswers += Int(entry.correctAnswers)
            stat.totalAttempts += Int(entry.totalAttempts)
            stats[code] = stat
        }
        save()
    }

    // Chinese names from the two Unity catalogues that differ from the native catalogue.
    private static let legacyCountryCodes = [
        "中非共和國": "CF",
        "伊朗（伊斯蘭共和國）": "IR",
        "俄羅斯聯邦": "RU",
        "剛果（民主共和國）": "CD",
        "加薩走廊": "PS",
        "台灣": "TW",
        "吉爾吉斯斯坦": "KG",
        "喬治亞州": "GE",
        "坦尚尼亞聯合共和國": "TZ",
        "多明尼加共和國": "DO",
        "密克羅尼西亞（聯邦）": "FM",
        "寮國人民民主共和國": "LA",
        "巴勒斯坦領土（被佔領）": "PS",
        "巴布亞紐幾內亞": "PG",
        "幾內亞比紹": "GW",
        "捷克共和國": "CZ",
        "摩爾多瓦（共和國）": "MD",
        "教廷（梵蒂岡城國）": "VA",
        "朝鮮（民主主義人民共和國）": "KP",
        "汶萊達魯薩蘭國": "BN",
        "波士尼亞與赫塞哥維納": "BA",
        "湯加": "TO",
        "澳洲": "AU",
        "科特迪瓦": "CI",
        "約旦河西岸": "PS",
        "聖基茨和尼維斯": "KN",
        "聖多美和普林西比": "ST",
        "阿拉伯利比亞民眾國": "LY",
        "阿拉伯敘利亞共和國": "SY",
        "阿拉伯聯合大公國": "AE",
        "韓國（共和國）": "KR",
        "馬紹爾群島": "MH",
        "馬裡": "ML",
    ]

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
