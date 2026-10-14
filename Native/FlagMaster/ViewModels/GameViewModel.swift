import Foundation
import UIKit

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
    @Published var phase: Phase = .playing
    @Published private(set) var errorMessage: String?

    let mode: GameMode
    private let stats: StatsStore
    private let settings: AppSettings
    private var allCountries: [Country] = []
    private var usedCodes = Set<String>()
    private var timer: Timer?
    private var questionToken = UUID()
    private let questionLimit = 20

    init(mode: GameMode, stats: StatsStore, settings: AppSettings) {
        self.mode = mode
        self.stats = stats
        self.settings = settings
        do {
            allCountries = try CountryRepository.load()
            if mode == .review && stats.weakestCountryCodes().isEmpty {
                errorMessage = "review-empty"
                phase = .finished
            } else {
                startTimerIfNeeded()
                makeQuestion()
            }
        } catch {
            errorMessage = error.localizedDescription
            phase = .finished
        }
    }

    func select(_ country: Country) {
        guard phase == .playing, selectedCode == nil, let correct = question else { return }
        selectedCode = country.abb2
        let isCorrect = country == correct
        totalQuestions += 1
        if isCorrect { correctAnswers += 1 } else { wrongAnswers.append(WrongAnswer(country: correct, selected: country)) }
        stats.record(correct, correct: isCorrect)
        feedback(success: isCorrect)

        if mode == .twoLives && !isCorrect {
            lives -= 1
            if lives == 0 { scheduleFinish(after: 1.2); return }
        }
        if mode == .speedRound && totalQuestions >= questionLimit {
            scheduleFinish(after: 1.2); return
        }
        scheduleNext(after: mode == .timedChallenge ? 0.45 : 1.25)
    }

    func togglePause() {
        guard phase != .finished else { return }
        phase = phase == .paused ? .playing : .paused
    }

    func restart() {
        timer?.invalidate()
        usedCodes = []
        wrongAnswers = []
        selectedCode = nil
        correctAnswers = 0
        totalQuestions = 0
        lives = 2
        phase = .playing
        errorMessage = nil
        startTimerIfNeeded()
        makeQuestion()
    }

    func stop() { timer?.invalidate() }

    func colorState(for country: Country) -> AnswerState {
        guard let selectedCode, let correct = question else { return .idle }
        if country == correct { return .correct }
        if country.abb2 == selectedCode { return .wrong }
        return .disabled
    }

    private func makeQuestion() {
        guard phase == .playing else { return }
        let pool: [Country]
        if mode == .review {
            let codes = Set(stats.weakestCountryCodes())
            pool = allCountries.filter { codes.contains($0.abb2) }
        } else {
            let unused = allCountries.filter { !usedCodes.contains($0.abb2) }
            pool = unused.isEmpty ? allCountries : unused
            if unused.isEmpty { usedCodes = [] }
        }
        guard let correct = pool.randomElement(), allCountries.count >= 4 else {
            phase = .finished
            return
        }
        usedCodes.insert(correct.abb2)
        question = correct
        choices = (Array(allCountries.filter { $0 != correct }.shuffled().prefix(3)) + [correct]).shuffled()
        selectedCode = nil
        questionToken = UUID()
        if mode == .speedRound { secondsRemaining = 5 }
    }

    private func startTimerIfNeeded() {
        guard mode == .timedChallenge || mode == .speedRound else { return }
        secondsRemaining = mode == .timedChallenge ? 60 : 5
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func tick() {
        guard phase == .playing else { return }
        secondsRemaining -= 1
        guard secondsRemaining <= 0 else { return }
        if mode == .timedChallenge {
            finish()
        } else if mode == .speedRound {
            timeOutQuestion()
        }
    }

    private func timeOutQuestion() {
        guard selectedCode == nil, let correct = question else { return }
        selectedCode = ""
        totalQuestions += 1
        wrongAnswers.append(WrongAnswer(country: correct, selected: nil))
        stats.record(correct, correct: false)
        feedback(success: false)
        if totalQuestions >= questionLimit { scheduleFinish(after: 1.0) }
        else { scheduleNext(after: 1.0) }
    }

    private func scheduleNext(after delay: TimeInterval) {
        let token = questionToken
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, self.questionToken == token, self.phase == .playing else { return }
            self.makeQuestion()
        }
    }

    private func scheduleFinish(after delay: TimeInterval) {
        let token = questionToken
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, self.questionToken == token else { return }
            self.finish()
        }
    }

    private func finish() {
        timer?.invalidate()
        phase = .finished
    }

    private func feedback(success: Bool) {
        guard settings.soundVolume != .off else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .error)
    }
}

enum AnswerState { case idle, correct, wrong, disabled }
