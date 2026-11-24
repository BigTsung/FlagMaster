import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class GameViewModel: ObservableObject {
    enum Phase: Equatable { case playing, paused, finished }
    enum FinishReason { case manual, completed, timeExpired, livesExhausted }

    @Published private(set) var soundEvent: GameSoundEvent?
    private var soundSequence = 0

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
    /// The scripted question order for daily practice and the quiz; nil for free-play modes.
    @Published private(set) var plan: [PlannedQuestion]?
    @Published private(set) var planIndex = 0
    @Published private(set) var answerLog: [AnswerRecord] = []
    @Published private(set) var dailySecondsRemaining = Int(DailyPlan.duration)
    @Published private(set) var isNewBest = false
    private var dailyRemaining = DailyPlan.duration

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

    var isLearning: Bool { practice != nil || mode == .endless || mode == .review || mode == .daily || isRetryingMistakes }
    var roundLimit: Int? {
        if let plan { return plan.count }
        return isRetryingMistakes || mode == .review || practice != nil ? roundPool.count : (mode == .speedRound ? questionLimit : nil)
    }
    var currentStep: PlannedQuestion? { plan.flatMap { $0.indices.contains(planIndex) ? $0[planIndex] : nil } }
    var dailyTimeUp: Bool { mode == .daily && plan != nil && dailyRemaining <= 0 }
    var quizScore: Int { QuizPlan.score(correct: correctAnswers, total: totalQuestions) }
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
        if plan != nil { answerLog.append(AnswerRecord(country: question, correct: correct, stage: currentStep?.stage)) }
        emitSound(selected == nil ? .timeout : (correct ? .correct : .wrong))
        stats.record(question, correct: correct)
        feedback(success: correct)
        shouldFinish = (mode == .twoLives && !isRetryingMistakes && lives == 0)
            || roundLimit.map { totalQuestions >= $0 } == true
            || dailyTimeUp
        // Practice answers remain visible until the learner is ready.
        transitionRemaining = isLearning ? nil : (mode == .timedChallenge ? 0.65 : mode == .quiz ? 1.1 : 1.4)
    }

    func continueLearning() {
        guard isLearning, phase == .playing, selectedCode != nil else { return }
        if shouldFinish || dailyTimeUp { finish(reason: naturalFinishReason) } else { makeQuestion() }
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
        plan = nil
        if practice == nil, mode == .daily || mode == .quiz {
            plan = mode == .daily
                ? DailyPlan.build(countries: allCountries, stats: stats.stats)
                : QuizPlan.build(countries: allCountries)
            roundPool = plan?.map(\.country) ?? []
            beginRound()
            return
        }
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
        plan = nil
        isRetryingMistakes = true
        beginRound()
    }

    private func beginRound() {
        stop()
        soundEvent = nil
        usedCodes = []
        wrongAnswers = []
        answerLog = []
        planIndex = 0
        isNewBest = false
        dailyRemaining = DailyPlan.duration
        dailySecondsRemaining = Int(DailyPlan.duration)
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

    func finish(reason: FinishReason = .manual) {
        guard phase != .finished else { return }
        stop()
        phase = .finished
        guard errorMessage == nil else { return }
        if plan != nil, reason == .completed {
            if mode == .daily { settings.recordDailyPractice() }
            if mode == .quiz, totalQuestions == plan?.count { isNewBest = settings.recordQuizScore(quizScore) }
        }
        switch reason {
        case .manual, .timeExpired: emitSound(.end)
        case .completed: emitSound(.complete)
        case .livesExhausted: emitSound(.gameOver)
        }
    }

    private var naturalFinishReason: FinishReason {
        mode == .twoLives && !isRetryingMistakes && lives == 0 ? .livesExhausted : .completed
    }

    private func emitSound(_ effect: SoundEffect) {
        soundSequence += 1
        soundEvent = GameSoundEvent(id: soundSequence, effect: effect)
    }

    func colorState(for country: Country) -> AnswerState {
        guard let selectedCode, let question else { return .idle }
        if country == question { return .correct }
        if country.abb2 == selectedCode { return .wrong }
        return .disabled
    }

    private func makeQuestion() {
        guard phase == .playing else { return }
        if let plan {
            let next = question == nil ? 0 : planIndex + 1
            guard plan.indices.contains(next) else { finish(reason: .completed); return }
            planIndex = next
            present(plan[next])
            return
        }
        var unused = roundPool.filter { !usedCodes.contains($0.abb2) }
        if unused.isEmpty {
            if mode == .review || isRetryingMistakes || practice != nil { finish(reason: .completed); return }
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

    private func present(_ step: PlannedQuestion) {
        let correct = step.country
        let region = StudyRegion.of(correct.abb2)
        let others = allCountries.filter { $0 != correct }
        let sameRegion = others.filter { region != nil && StudyRegion.of($0.abb2) == region }
        let preferred: [Country]
        switch step.distractors {
        case .easy: preferred = region == nil ? others : others.filter { StudyRegion.of($0.abb2) != region }
        case .mixed: preferred = others
        case .regional: preferred = sameRegion
        }
        var distractors = step.counterpart.flatMap { code in others.first { $0.abb2 == code } }.map { [$0] } ?? []
        for pool in [preferred.shuffled(), others.shuffled()] {
            for country in pool where distractors.count < 3 && !distractors.contains(country) { distractors.append(country) }
        }
        question = correct
        usedCodes.insert(correct.abb2)
        choices = (distractors + [correct]).shuffled()
        selectedCode = nil
        transitionRemaining = nil
    }

    // One clock drives both countdowns and answer feedback, so pausing freezes both.
    // Exposed internally for deterministic regression tests without wall-clock sleeps.
    func advance(by elapsed: TimeInterval) {
        guard phase == .playing, elapsed > 0 else { return }
        if mode == .daily, plan != nil, dailyRemaining > 0 {
            dailyRemaining = max(0, dailyRemaining - elapsed)
            dailySecondsRemaining = Int(ceil(dailyRemaining))
            // Time is up: the current question is still finished before the session ends.
            if dailyRemaining == 0 { shouldFinish = shouldFinish || selectedCode != nil }
        }
        if !isLearning && (mode == .timedChallenge || (mode == .speedRound && selectedCode == nil)) {
            let previousSeconds = secondsRemaining
            remaining = max(0, remaining - elapsed)
            secondsRemaining = Int(ceil(remaining))
            if remaining == 0 {
                if mode == .timedChallenge { finish(reason: .timeExpired); return }
                selectedCode = ""
                registerAnswer(correct: false, selected: nil)
                return
            }
            let warningWindow = mode == .timedChallenge ? 3 : 1
            if selectedCode == nil, secondsRemaining <= warningWindow, secondsRemaining < previousSeconds {
                emitSound(.countdown)
            }
        }
        if let delay = transitionRemaining {
            transitionRemaining = delay - elapsed
            if delay <= elapsed {
                transitionRemaining = nil
                if shouldFinish { finish(reason: naturalFinishReason) } else { makeQuestion() }
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

struct AnswerRecord: Identifiable, Sendable {
    let id = UUID()
    let country: Country
    let correct: Bool
    let stage: PlannedQuestion.Stage?
}
