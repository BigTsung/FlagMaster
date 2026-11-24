import Foundation
import Testing
@testable import FlagMasterCore

@MainActor
struct DailyQuizTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func catalogue() throws -> [Country] {
        let native = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try JSONDecoder().decode([Country].self, from: Data(contentsOf: native.appendingPathComponent("FlagMaster/Resources/countries.json")))
    }
    private func environment() -> (StatsStore, AppSettings) {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "daily-\(UUID())")!)
        settings.soundVolume = .off
        return (StatsStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("daily-\(UUID()).json")), settings)
    }
    private func stat(_ code: String, correct: Int, total: Int, stage: Int, due: Date) -> CountryStat {
        CountryStat(countryCode: code, correctAnswers: correct, totalAttempts: total, lastReviewedAt: due, nextReviewAt: due, reviewStage: stage)
    }

    @Test func newLearnerStartsWithFamousFlagsAndRecallsThemAgain() throws {
        let plan = DailyPlan.build(countries: try catalogue(), stats: [:], now: now)
        let learn = plan.filter { $0.stage == .learn }
        #expect(learn.map(\.country.abb2) == Array(DailyPlan.starterCodes.prefix(6)))
        #expect(learn.allSatisfy { $0.distractors == .easy })
        let recap = plan.filter { $0.stage == .recap }
        #expect(Set(recap.map(\.country.abb2)) == Set(learn.map(\.country.abb2)))
        #expect(recap.allSatisfy { $0.distractors == .regional })
        // Stages always progress in order.
        #expect(plan.map(\.stage.rawValue) == plan.map(\.stage.rawValue).sorted())
    }

    @Test func backlogReducesNewFlagsAndWeakFlagsBringTheirLookAlike() throws {
        let countries = try catalogue()
        var stats: [String: CountryStat] = [:]
        let old = now.addingTimeInterval(-86_400)
        for code in ["JP", "FR", "DE", "BR", "IT", "ES", "CA", "MX", "IN", "AU"] {
            stats[code] = stat(code, correct: 1, total: 1, stage: 1, due: old)
        }
        stats["IE"] = stat("IE", correct: 1, total: 4, stage: 0, due: now.addingTimeInterval(600))
        let plan = DailyPlan.build(countries: countries, stats: stats, now: now)
        #expect(plan.filter { $0.stage == .warmUp }.count == DailyPlan.maxWarmUp)
        #expect(plan.filter { $0.stage == .learn }.count == 4)
        let ireland = plan.first { $0.country.abb2 == "IE" }
        #expect(ireland?.stage == .reinforce)
        #expect(ireland?.counterpart == "CI")
        #expect(Set(plan.filter { $0.stage != .recap }.map(\.country.abb2)).count == plan.filter { $0.stage != .recap }.count)
    }

    @Test func dailyFinishesCurrentQuestionWhenTimeRunsOutAndRecordsStreak() throws {
        let (stats, settings) = environment()
        let game = GameViewModel(mode: .daily, stats: stats, settings: settings, countries: try catalogue(), automaticTimer: false)
        #expect(game.currentStep?.stage == .learn)
        #expect(game.isLearning)
        game.advance(by: DailyPlan.duration + 5)
        #expect(game.dailySecondsRemaining == 0)
        #expect(game.phase == .playing)
        game.select(game.question!)
        game.continueLearning()
        #expect(game.phase == .finished)
        #expect(settings.practicedToday())
        #expect(settings.dailyStreak() == 1)
    }

    @Test func dailyChoicesFollowDifficulty() throws {
        let (stats, settings) = environment()
        let game = GameViewModel(mode: .daily, stats: stats, settings: settings, countries: try catalogue(), automaticTimer: false)
        while game.phase == .playing {
            let step = game.currentStep!
            let region = StudyRegion.of(step.country.abb2)
            let others = game.choices.filter { $0 != step.country }
            #expect(game.choices.count == 4 && Set(game.choices).count == 4)
            if step.distractors == .easy { #expect(others.allSatisfy { StudyRegion.of($0.abb2) != region }) }
            if step.distractors == .regional { #expect(others.allSatisfy { StudyRegion.of($0.abb2) == region }) }
            game.select(game.question!)
            game.continueLearning()
        }
        #expect(game.totalQuestions == game.plan?.count)
    }

    @Test func quizHasTwentyUniqueQuestionsAcrossEveryRegion() throws {
        var generator = SystemRandomNumberGenerator()
        let plan = QuizPlan.build(countries: try catalogue(), using: &generator)
        #expect(plan.count == 20)
        #expect(Set(plan.map(\.country.abb2)).count == 20)
        for region in StudyRegion.allCases {
            #expect(plan.contains { StudyRegion.of($0.country.abb2) == region })
        }
    }

    @Test func quizAutoAdvancesScoresAndKeepsBest() throws {
        let (stats, settings) = environment()
        let game = GameViewModel(mode: .quiz, stats: stats, settings: settings, countries: try catalogue(), automaticTimer: false)
        #expect(!game.isLearning)
        #expect(game.roundLimit == 20)
        for index in 0..<20 {
            game.select(index < 17 ? game.question! : game.choices.first { $0 != game.question }!)
            game.advance(by: 2)
        }
        #expect(game.phase == .finished)
        #expect(game.quizScore == 85)
        #expect(game.isNewBest)
        #expect(settings.bestQuizScore == 85)
        #expect(QuizPlan.grade(85) == "A")
        game.retryMistakes()
        #expect(game.plan == nil && game.question != nil && game.roundLimit == 3)
    }

    @Test func streakContinuesOnlyFromYesterday() {
        let (_, settings) = environment()
        let calendar = Calendar(identifier: .gregorian)
        settings.recordDailyPractice(now: now, calendar: calendar)
        settings.recordDailyPractice(now: now, calendar: calendar)
        #expect(settings.dailyStreak(now: now, calendar: calendar) == 1)
        let tomorrow = now.addingTimeInterval(86_400)
        settings.recordDailyPractice(now: tomorrow, calendar: calendar)
        #expect(settings.dailyStreak(now: tomorrow, calendar: calendar) == 2)
        let later = tomorrow.addingTimeInterval(3 * 86_400)
        #expect(settings.dailyStreak(now: later, calendar: calendar) == 0)
        settings.recordDailyPractice(now: later, calendar: calendar)
        #expect(settings.dailyStreak(now: later, calendar: calendar) == 1)
    }
}
