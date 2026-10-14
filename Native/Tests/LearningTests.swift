import Foundation
import Testing
@testable import FlagMasterCore

@MainActor
struct LearningTests {
    private let epoch = Date(timeIntervalSince1970: 1_800_000_000)
    private func catalogue() throws -> [Country] {
        let native = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode([Country].self, from: Data(contentsOf: native.appendingPathComponent("FlagMaster/Resources/countries.json")))
    }
    private func mapCountries() throws -> [WorldMapCountry] {
        let native = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: native.appendingPathComponent("FlagMaster/Resources/world-map.geojson"))
        return WorldMapData.decode(data)
    }
    private func store() -> StatsStore {
        StatsStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("learning-\(UUID()).json"))
    }
    private func settings() -> AppSettings {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "learning-\(UUID())")!)
        settings.soundVolume = .off
        return settings
    }

    @Test func oldHistoryMigratesWithoutLosingCounts() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(#"[{"countryCode":"JP","correctAnswers":4,"totalAttempts":5}]"#.utf8).write(to: url)
        let stats = StatsStore(fileURL: url)
        #expect(stats.attempts == 5)
        #expect(stats.correct == 4)
        #expect(stats.dueCountryCodes(at: epoch) == ["JP"])
        let japan = try #require(catalogue().first { $0.abb2 == "JP" })
        stats.record(japan, correct: true, at: epoch)
        let reloaded = StatsStore(fileURL: url)
        #expect(reloaded.attempts == 6)
        #expect(reloaded.stats["JP"]?.reviewStage == 1)
        #expect(reloaded.stats["JP"]?.nextReviewAt == epoch.addingTimeInterval(86_400))
    }

    @Test func scheduleUsesDueSuccessesAndCapsAtThirtyDays() throws {
        let stats = store(), country = try #require(catalogue().first)
        var date = epoch
        for days in [1, 3, 7, 14, 30, 30] {
            stats.record(country, correct: true, at: date)
            let due = try #require(stats.stats[country.abb2]?.nextReviewAt)
            #expect(due == date.addingTimeInterval(Double(days) * 86_400))
            #expect(stats.dueCountryCodes(at: due.addingTimeInterval(-1)).isEmpty)
            #expect(stats.dueCountryCodes(at: due) == [country.abb2])
            date = due
        }
        #expect(stats.stats[country.abb2]?.reviewStage == 5)
        #expect(stats.mastered == 1)
    }

    @Test func earlyPracticeDoesNotInflateMastery() throws {
        let stats = store(), country = try #require(catalogue().first)
        stats.record(country, correct: true, at: epoch)
        for offset in 1...5 { stats.record(country, correct: true, at: epoch.addingTimeInterval(Double(offset))) }
        #expect(stats.stats[country.abb2]?.reviewStage == 1)
        #expect(stats.stats[country.abb2]?.nextReviewAt == epoch.addingTimeInterval(86_400))
        #expect(stats.attempts == 6)
        #expect(stats.mastered == 0)
    }

    @Test func mistakeResetsScheduleAndMastery() throws {
        let stats = store(), country = try #require(catalogue().first)
        stats.record(country, correct: true, at: epoch)
        stats.record(country, correct: true, at: epoch.addingTimeInterval(86_400))
        stats.record(country, correct: true, at: epoch.addingTimeInterval(4 * 86_400))
        #expect(stats.mastered == 1)
        let date = epoch.addingTimeInterval(5 * 86_400)
        stats.record(country, correct: false, at: date)
        #expect(stats.mastered == 0)
        #expect(stats.stats[country.abb2]?.nextReviewAt == date.addingTimeInterval(600))
        #expect(stats.stats[country.abb2]?.needsPractice == true)
    }

    @Test func dueQueuePrioritizesOldestAndHonorsLimit() throws {
        let countries = try catalogue(), stats = store()
        stats.record(countries[0], correct: false, at: epoch)
        stats.record(countries[1], correct: false, at: epoch.addingTimeInterval(-100))
        stats.record(countries[2], correct: true, at: epoch)
        #expect(stats.dueCountryCodes(at: epoch.addingTimeInterval(600), limit: 1) == [countries[1].abb2])
        #expect(stats.dueCountryCodes(at: epoch.addingTimeInterval(600), limit: -1).isEmpty)
    }

    @Test func allCountriesHaveExactlyOneStudyRegionExceptEU() throws {
        let countries = try catalogue()
        for country in countries {
            let regions = StudyRegion.allCases.filter { $0.codes.contains(country.abb2) }
            #expect(regions.count == (country.abb2 == "EU" ? 0 : 1), "\(country.abb2) mapping")
        }
        let catalogueCodes = Set(countries.map(\.abb2))
        for region in StudyRegion.allCases {
            #expect(region.codes.isSubset(of: catalogueCodes))
            #expect(region.countries(in: countries).count >= 10)
        }
    }

    @Test func detailedWorldMapContainsValidGeometryForEveryRegion() throws {
        let countries = try mapCountries()
        #expect(countries.count >= 170)
        #expect(Set(countries.compactMap(\.region)) == Set(StudyRegion.allCases))
        for country in countries {
            #expect(!country.name.isEmpty)
            #expect(!country.polygons.isEmpty)
            for coordinate in country.polygons.flatMap({ $0 }).flatMap({ $0 }) {
                #expect((-180.0...180.0).contains(coordinate.longitude))
                #expect((-90.0...90.0).contains(coordinate.latitude))
            }
        }
    }

    @Test func eachRegionalJourneyIsFiniteAndStaysWithinRegion() throws {
        let countries = try catalogue()
        for region in StudyRegion.allCases {
            let game = GameViewModel(mode: .endless, stats: store(), settings: settings(), countries: countries, automaticTimer: false, practice: .region(region))
            #expect(game.roundLimit == 10)
            var seen = Set<String>()
            for _ in 0..<10 {
                let question = try #require(game.question)
                #expect(seen.insert(question.abb2).inserted)
                #expect(game.choices.count == 4)
                #expect(game.choices.allSatisfy { region.codes.contains($0.abb2) })
                game.select(question)
                game.continueLearning()
            }
            #expect(game.phase == .finished)
        }
    }

    @Test func regionalTripPrioritizesUnseenFlags() throws {
        let countries = try catalogue(), stats = store()
        let members = StudyRegion.southAmerica.countries(in: countries)
        stats.record(members[0], correct: true)
        stats.record(members[1], correct: true)
        let seen = Set(members.prefix(2).map(\.abb2))
        let game = GameViewModel(mode: .endless, stats: stats, settings: settings(), countries: countries, automaticTimer: false, practice: .region(.southAmerica))
        for _ in 0..<10 {
            let question = try #require(game.question)
            #expect(!seen.contains(question.abb2))
            game.select(question); game.continueLearning()
        }
    }

    @Test func comparisonsAlwaysIncludeCounterpartAndFinishAfterTwo() throws {
        let countries = try catalogue()
        for pair in FlagComparison.all {
            #expect(pair.codes.isSubset(of: Set(countries.map(\.abb2))))
            let game = GameViewModel(mode: .endless, stats: store(), settings: settings(), countries: countries, automaticTimer: false, practice: .comparison(pair))
            var seen = Set<String>()
            for _ in 0..<2 {
                let question = try #require(game.question)
                #expect(pair.codes.contains(question.abb2))
                #expect(seen.insert(question.abb2).inserted)
                #expect(pair.codes.isSubset(of: Set(game.choices.map(\.abb2))))
                #expect(Set(game.choices).count == 4)
                #expect(game.comparison == nil)
                game.select(question)
                #expect(game.comparison == pair)
                game.continueLearning()
            }
            #expect(game.phase == .finished)
        }
    }

    @Test func comparisonMatchingIsSymmetric() {
        for pair in FlagComparison.all {
            #expect(FlagComparison.match(pair.first, pair.second) == pair)
            #expect(FlagComparison.match(pair.second, pair.first) == pair)
            #expect(FlagComparison.match(pair.first, pair.first) == nil)
        }
    }
    @Test func reviewExcludesFutureFlagsAndDoesNotRepeatAfterCompletion() throws {
        let countries = try catalogue(), stats = store()
        let now = Date()
        stats.record(countries[0], correct: true, at: now.addingTimeInterval(-2 * 86_400))
        stats.record(countries[1], correct: true, at: now)
        let game = GameViewModel(mode: .review, stats: stats, settings: settings(), countries: countries, automaticTimer: false)
        #expect(game.roundLimit == 1)
        #expect(game.question == countries[0])
        game.select(countries[0]); game.continueLearning()
        #expect(game.phase == .finished)
        #expect(stats.dueCountryCodes().isEmpty)
        game.restart()
        #expect(game.errorMessage == "review-empty")
    }

}
