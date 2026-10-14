import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class GameViewModel: ObservableObject {
    enum Phase: Equatable { case playing, paused, finished }

    @Published private(set) var question: Country?
    @Published private(set) var choices: [Country] = []
    @Published private(set) var selectedCode: String?
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var lives = 2
    @Published private(set) var secondsRemaining = 0
    @Published private(set) var wrongAnswers: [WrongAnswer] = []
    @Published private(set) var phase: Phase = .playing
    @Published private(set) var errorMessage: String?
    @Published private(set) var streak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var isRetryingMistakes = false

    let mode: GameMode
    let practice: PracticePlan?
    private let stats: StatsStore
    private let settings: AppSettings
    private var allCountries: [Country] = []
    private var roundPool: [Country] = []
    private var usedCodes = Set<String>()
    private var timer: Timer?
    private var remaining: TimeInterval = 0
    private var transitionRemaining: TimeInterval?
    private var shouldFinish = false
    private var lastTick = Date()
    private let automaticTimer: Bool
    private let questionLimit = 20

    var isLearning: Bool { practice != nil || mode == .endless || mode == .review || isRetryingMistakes }
    var roundLimit: Int? { isRetryingMistakes || mode == .review || practice != nil ? roundPool.count : (mode == .speedRound ? questionLimit : nil) }
    var accuracy: Double { totalQuestions == 0 ? 0 : Double(correctAnswers) / Double(totalQuestions) }

    init(mode: GameMode, stats: StatsStore, settings: AppSettings,
         countries: [Country]? = nil, automaticTimer: Bool = true, practice: PracticePlan? = nil) {
        self.mode = mode
        self.practice = practice
        self.stats = stats
        self.settings = settings
        self.automaticTimer = automaticTimer
        do {
            allCountries = try countries ?? CountryRepository.load()
            restart()
        } catch {
            errorMessage = error.localizedDescription
            phase = .finished
        }
    }

    var comparison: FlagComparison? {
        guard selectedCode != nil, let question else { return nil }
        if case .comparison(let pair) = practice { return pair }
        guard let selectedCode else { return nil }
        return FlagComparison.match(question.abb2, selectedCode)
    }
    var comparisonCountries: [Country] {
        guard let comparison else { return [] }
        return allCountries.filter { comparison.codes.contains($0.abb2) }
    }

    func select(_ country: Country) {
        guard phase == .playing, selectedCode == nil, choices.contains(country), let correct = question else { return }
        selectedCode = country.abb2
        registerAnswer(correct: country == correct, selected: country)
    }

    private func registerAnswer(correct: Bool, selected: Country?) {
        guard let question else { return }
        totalQuestions += 1
        if correct {
            correctAnswers += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            streak = 0
            wrongAnswers.append(WrongAnswer(country: question, selected: selected))
            if mode == .twoLives && !isRetryingMistakes { lives -= 1 }
        }
        stats.record(question, correct: correct)
        feedback(success: correct)
        shouldFinish = (mode == .twoLives && !isRetryingMistakes && lives == 0)
            || roundLimit.map { totalQuestions >= $0 } == true
        // Practice answers remain visible until the learner is ready.
        transitionRemaining = isLearning ? nil : (mode == .timedChallenge ? 0.65 : 1.4)
    }

    func continueLearning() {
        guard isLearning, phase == .playing, selectedCode != nil else { return }
        if shouldFinish { finish() } else { makeQuestion() }
    }

    func pause() {
        guard phase == .playing else { return }
        phase = .paused
    }

    func togglePause() {
        guard phase != .finished else { return }
        phase = phase == .paused ? .playing : .paused
        lastTick = Date()
    }

    func restart() {
        isRetryingMistakes = false
        switch practice {
        case .region(let region):
            // Prioritize unseen flags, then the least familiar. No repeats within a journey.
            roundPool = Array(region.countries(in: allCountries).shuffled().sorted {
                let a = stats.stats[$0.abb2], b = stats.stats[$1.abb2]
                if (a == nil) != (b == nil) { return a == nil }
                return (a?.reviewStage ?? 0) < (b?.reviewStage ?? 0)
            }.prefix(10))
        case .comparison(let pair): roundPool = allCountries.filter { pair.codes.contains($0.abb2) }
        case nil:
            let codes = stats.dueCountryCodes()
            let byCode = Dictionary(uniqueKeysWithValues: allCountries.map { ($0.abb2, $0) })
            roundPool = mode == .review ? codes.compactMap { byCode[$0] } : allCountries
        }
        beginRound()
    }

    func retryMistakes() {
        let codes = Set(wrongAnswers.map { $0.country.abb2 })
        guard !codes.isEmpty else { return }
        roundPool = allCountries.filter { codes.contains($0.abb2) }
        isRetryingMistakes = true
        beginRound()
    }

    private func beginRound() {
        stop()
        usedCodes = []
        wrongAnswers = []
        question = nil
        choices = []
        selectedCode = nil
        correctAnswers = 0
        totalQuestions = 0
        streak = 0
        bestStreak = 0
        lives = 2
        shouldFinish = false
        phase = .playing
        errorMessage = nil
        guard allCountries.count >= 4 else { errorMessage = "missing-data"; finish(); return }
        guard !roundPool.isEmpty else { errorMessage = mode == .review ? "review-empty" : "missing-data"; finish(); return }
        remaining = mode == .timedChallenge ? 60 : 5
        secondsRemaining = Int(remaining)
        makeQuestion()
        lastTick = Date()
        if automaticTimer {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let now = Date()
                    self.advance(by: max(0, now.timeIntervalSince(self.lastTick)))
                    self.lastTick = now
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        transitionRemaining = nil
    }

    func finish() {
        stop()
        phase = .finished
    }

    func colorState(for country: Country) -> AnswerState {
        guard let selectedCode, let question else { return .idle }
        if country == question { return .correct }
        if country.abb2 == selectedCode { return .wrong }
        return .disabled
    }

    private func makeQuestion() {
        guard phase == .playing else { return }
        var unused = roundPool.filter { !usedCodes.contains($0.abb2) }
        if unused.isEmpty {
            if mode == .review || isRetryingMistakes || practice != nil { finish(); return }
            usedCodes = []
            unused = roundPool
        }
        guard let correct = mode == .review && !isRetryingMistakes ? unused.first : unused.randomElement() else { finish(); return }
        usedCodes.insert(correct.abb2)
        question = correct
        let distractorPool: [Country]
        if case .region(let region) = practice { distractorPool = region.countries(in: allCountries) }
        else { distractorPool = allCountries }
        var distractors: [Country] = []
        if case .comparison(let pair) = practice,
           let counterpart = allCountries.first(where: { pair.codes.contains($0.abb2) && $0 != correct }) {
            distractors.append(counterpart)
        }
        distractors += Array(distractorPool.filter { $0 != correct && !distractors.contains($0) }.shuffled().prefix(3 - distractors.count))
        choices = (distractors + [correct]).shuffled()
        selectedCode = nil
        transitionRemaining = nil
        if mode == .speedRound { remaining = 5; secondsRemaining = 5 }
    }

    // One clock drives both countdowns and answer feedback, so pausing freezes both.
    // Exposed internally for deterministic regression tests without wall-clock sleeps.
    func advance(by elapsed: TimeInterval) {
        guard phase == .playing, elapsed > 0 else { return }
        if !isLearning && (mode == .timedChallenge || (mode == .speedRound && selectedCode == nil)) {
            remaining = max(0, remaining - elapsed)
            secondsRemaining = Int(ceil(remaining))
            if remaining == 0 {
                if mode == .timedChallenge { finish(); return }
                selectedCode = ""
                registerAnswer(correct: false, selected: nil)
                return
            }
        }
        if let delay = transitionRemaining {
            transitionRemaining = delay - elapsed
            if delay <= elapsed {
                transitionRemaining = nil
                if shouldFinish { finish() } else { makeQuestion() }
            }
        }
    }

    private func feedback(success: Bool) {
        guard settings.hapticsEnabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(success ? .success : .error)
        #endif
    }
}

enum AnswerState { case idle, correct, wrong, disabled }
