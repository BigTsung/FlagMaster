import SwiftUI

struct GameView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @StateObject private var model: GameViewModel
    let exit: () -> Void

    init(mode: GameMode, stats: StatsStore, settings: AppSettings, exit: @escaping () -> Void) {
        _model = StateObject(wrappedValue: GameViewModel(mode: mode, stats: stats, settings: settings))
        self.exit = exit
    }

    var body: some View {
        VStack(spacing: 18) {
            header
            Spacer(minLength: 0)
            if let country = model.question {
                FlagImage(code: country.abb2)
                    .frame(maxWidth: 430, maxHeight: 230)
                    .padding(.horizontal, 22)
                    .transition(.scale.combined(with: .opacity))
                    .id(country.id)
                Text(settings.language == .english ? "Which country is this?" : "這是哪一個國家？")
                    .font(.title3.bold())
                choices
            }
            Spacer(minLength: 10)
        }
        .padding(.top, 8)
        .foregroundStyle(.white)
        .overlay { if model.phase == .paused { pauseOverlay } }
        .overlay { if model.phase == .finished { resultOverlay } }
        .onDisappear { model.stop() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { model.togglePause() } label: { Image(systemName: "pause.fill").frame(width: 42, height: 42).background(.white.opacity(0.12), in: Circle()) }
            VStack(alignment: .leading, spacing: 2) {
                Text(model.mode.title(settings.language)).font(.headline)
                Text("\(model.correctAnswers) / \(model.totalQuestions)").font(.caption).foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            if model.mode == .twoLives { Label("\(model.lives)", systemImage: "heart.fill").foregroundStyle(.pink) }
            if model.mode == .timedChallenge || model.mode == .speedRound {
                Label("\(model.secondsRemaining)", systemImage: "timer")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(model.secondsRemaining <= 3 ? .yellow : .white)
            }
            if model.mode == .speedRound { Text("\(max(0, 20 - model.totalQuestions))").font(.headline.monospacedDigit()) }
        }
        .padding(.horizontal, 18)
    }

    private var choices: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(model.choices) { country in
                Button { model.select(country) } label: {
                    Text(country.name(for: settings.language))
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 62)
                        .padding(.horizontal, 8)
                        .background(answerColor(model.colorState(for: country)), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.17)))
                }
                .buttonStyle(.plain)
                .disabled(model.selectedCode != nil)
            }
        }.padding(.horizontal, 18).frame(maxWidth: 620)
    }

    private func answerColor(_ state: AnswerState) -> Color {
        switch state {
        case .idle: .white.opacity(0.14)
        case .correct: .green.opacity(0.82)
        case .wrong: .red.opacity(0.82)
        case .disabled: .white.opacity(0.07)
        }
    }

    private var pauseOverlay: some View {
        ModalCard {
            Image(systemName: "pause.circle.fill").font(.system(size: 56)).foregroundStyle(.yellow)
            Text(settings.language == .english ? "Paused" : "遊戲暫停").font(.largeTitle.bold())
            Button(settings.language == .english ? "Continue" : "繼續") { model.togglePause() }.buttonStyle(PrimaryButtonStyle())
            Button(settings.language == .english ? "Restart" : "重新開始") { model.restart() }.buttonStyle(SecondaryCapsuleStyle())
            Button(settings.language == .english ? "Main Menu" : "回主選單", action: exit).buttonStyle(SecondaryCapsuleStyle())
        }
    }

    private var resultOverlay: some View {
        ModalCard {
            Image(systemName: model.errorMessage == nil ? "trophy.fill" : "info.circle.fill").font(.system(size: 54)).foregroundStyle(.yellow)
            Text(resultTitle).font(.largeTitle.bold()).multilineTextAlignment(.center)
            if model.errorMessage == nil {
                Text("\(model.correctAnswers) / \(model.totalQuestions)").font(.system(size: 40, weight: .black, design: .rounded))
                if !model.wrongAnswers.isEmpty { Text(settings.language == .english ? "Missed: \(model.wrongAnswers.count)" : "答錯：\(model.wrongAnswers.count) 題").foregroundStyle(.secondary) }
                Button(settings.language == .english ? "Play Again" : "再玩一次") { model.restart() }.buttonStyle(PrimaryButtonStyle())
            }
            Button(settings.language == .english ? "Main Menu" : "回主選單", action: exit).buttonStyle(SecondaryCapsuleStyle())
        }
    }

    private var resultTitle: String {
        if model.errorMessage == "review-empty" { return settings.language == .english ? "No questions to review yet" : "目前沒有錯題可複習" }
        if model.errorMessage != nil { return settings.language == .english ? "Unable to load game data" : "無法載入遊戲資料" }
        return settings.language == .english ? "Round Complete" : "本局完成"
    }
}

private struct ModalCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        ZStack {
            Color.black.opacity(0.68).ignoresSafeArea()
            VStack(spacing: 18) { content }
                .padding(28).frame(maxWidth: 390)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
                .padding(22)
        }
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(.yellow.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule()).foregroundStyle(.black)
    }
}

private struct SecondaryCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 13)
            .background(.secondary.opacity(configuration.isPressed ? 0.15 : 0.25), in: Capsule())
    }
}

#Preview("Game – Endless") {
    let settings = AppSettings()
    let stats = StatsStore()

    ZStack {
        AppBackground()
        GameView(mode: .endless, stats: stats, settings: settings) { }
            .environmentObject(settings)
            .environmentObject(stats)
    }
}
