import Foundation
import Testing
@testable import FlagMasterCore

@MainActor
struct GameTests {
    private func fixture(_ mode: GameMode) -> (GameViewModel, StatsStore, AppSettings) {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "FlagMasterTests.\(UUID())")!)
        settings.soundVolume = .off
        let stats = StatsStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("flags-\(UUID()).json"))
        let countries = (0..<8).map { Country(cn: "國家\($0)", en: "Country \($0)", full: "Country \($0)", abb2: "C\($0)", abb3: "CC\($0)", code: "\($0)") }
        return (GameViewModel(mode: mode, stats: stats, settings: settings, countries: countries, automaticTimer: false), stats, settings)
    }

    @Test func choicesAreUniqueAndContainAnswer() {
        let (game, _, _) = fixture(.endless)
        #expect(game.choices.count == 4)
        #expect(Set(game.choices).count == 4)
        #expect(game.choices.contains(game.question!))
    }

    @Test func practiceWaitsForLearnerAndNeverRepeatsBeforePoolExhausted() {
        let (game, _, _) = fixture(.endless)
        var codes = Set<String>()
        for _ in 0..<8 {
            #expect(codes.insert(game.question!.abb2).inserted)
            let question = game.question
            game.select(question!)
            game.advance(by: 100)
            #expect(game.question == question)
            game.continueLearning()
        }
        #expect(game.phase == .playing)
        #expect(game.correctAnswers == 8)
    }

    @Test func doubleTapDoesNotRecordTwice() {
        let (game, stats, _) = fixture(.endless)
        game.select(game.question!)
        game.select(game.question!)
        #expect(game.totalQuestions == 1)
        #expect(stats.attempts == 1)
    }

    @Test func pauseDuringFeedbackResumesTransition() {
        let (game, _, _) = fixture(.speedRound)
        game.select(game.question!)
        game.advance(by: 0.3)
        game.togglePause()
        game.advance(by: 10)
        #expect(game.selectedCode != nil)
        game.togglePause()
        game.advance(by: 1.2)
        #expect(game.selectedCode == nil)
        #expect(game.secondsRemaining == 5)
    }

    @Test func speedTimeoutCountsOnceAndNeverGoesNegative() {
        let (game, stats, _) = fixture(.speedRound)
        game.advance(by: 5)
        #expect(game.totalQuestions == 1)
        #expect(game.wrongAnswers.first?.selected == nil)
        game.advance(by: 0.5)
        #expect(game.secondsRemaining == 0)
        #expect(stats.attempts == 1)
        game.advance(by: 1)
        #expect(game.secondsRemaining == 5)
    }

    @Test func speedRoundEndsAfterTwentyTimeouts() {
        let (game, _, _) = fixture(.speedRound)
        for _ in 0..<20 { game.advance(by: 5); game.advance(by: 1.5) }
        #expect(game.phase == .finished)
        #expect(game.totalQuestions == 20)
    }

    @Test func timedChallengePausesAndEndsAtSixtySeconds() {
        let (game, _, _) = fixture(.timedChallenge)
        game.advance(by: 30)
        game.pause()
        game.advance(by: 80)
        #expect(game.secondsRemaining == 30)
        game.togglePause()
        game.advance(by: 30)
        #expect(game.secondsRemaining == 0)
        #expect(game.phase == .finished)
    }

    @Test func twoLivesOnlyEndsAfterTwoMistakesAndRespectsPausedFinish() {
        let (game, _, _) = fixture(.twoLives)
        game.select(game.question!)
        game.advance(by: 2)
        for index in 0..<2 {
            game.select(game.choices.first { $0 != game.question }!)
            if index == 0 { game.advance(by: 2); #expect(game.phase == .playing) }
        }
        game.pause()
        game.advance(by: 5)
        #expect(game.phase == .paused)
        game.togglePause()
        game.advance(by: 2)
        #expect(game.lives == 0)
        #expect(game.phase == .finished)
    }

    @Test func restartDiscardsOldTransitionAndResetsStreak() {
        let (game, _, _) = fixture(.speedRound)
        game.select(game.question!)
        game.restart()
        let country = game.question
        game.advance(by: 2)
        #expect(game.question == country)
        #expect(game.selectedCode == nil)
        #expect(game.totalQuestions == 0)
        #expect(game.streak == 0)
        #expect(game.secondsRemaining == 3)
    }

    @Test func reviewOnlyIncludesMistakesAndHasFiniteRound() {
        let (base, stats, settings) = fixture(.endless)
        let country = base.question!
        base.select(base.choices.first { $0 != country }!)
        let countries = base.choices
        stats.record(country, correct: false, at: Date().addingTimeInterval(-601))
        stats.record(countries.first { $0 != country }!, correct: true)
        let review = GameViewModel(mode: .review, stats: stats, settings: settings, countries: countries, automaticTimer: false)
        #expect(review.question == country)
        #expect(review.roundLimit == 1)
        review.select(country)
        review.continueLearning()
        #expect(review.phase == .finished)
    }

    @Test func emptyReviewIsSafe() {
        let (game, _, _) = fixture(.review)
        #expect(game.phase == .finished)
        #expect(game.errorMessage == "review-empty")
        game.restart()
        #expect(game.phase == .finished)
    }

    @Test func retryUsesOnlyThisRoundsMistakesWithoutTimer() {
        let (game, _, _) = fixture(.timedChallenge)
        let missed = game.question!
        game.select(game.choices.first { $0 != missed }!)
        game.finish()
        game.retryMistakes()
        #expect(game.isLearning)
        #expect(game.question == missed)
        #expect(game.roundLimit == 1)
        game.advance(by: 120)
        #expect(game.phase == .playing)
        game.select(missed)
        game.continueLearning()
        #expect(game.phase == .finished)
    }

    @Test func persistenceAndClear() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("persist-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = StatsStore(fileURL: url)
        let (game, _, _) = fixture(.endless)
        store.record(game.question!, correct: true)
        #expect(StatsStore(fileURL: url).attempts == 1)
        store.clear()
        #expect(StatsStore(fileURL: url).attempts == 0)
    }

    @Test func bundledCountriesHaveUniqueCodesAndFlagFiles() throws {
        let native = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let resource = native.appendingPathComponent("FlagMaster/Resources")
        let countries = try JSONDecoder().decode([Country].self, from: Data(contentsOf: resource.appendingPathComponent("countries.json")))
        #expect(countries.count == 198)
        #expect(Set(countries.map(\.abb2)).count == countries.count)
        for country in countries {
            #expect(!country.cn.isEmpty && !country.en.isEmpty)
            #expect(FileManager.default.fileExists(atPath: resource.appendingPathComponent("Flags/\(country.abb2).png").path))
        }
    }
}
