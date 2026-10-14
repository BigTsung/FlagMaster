import SwiftUI

struct GameView: View {
    @EnvironmentObject private var stats: StatsStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model: GameViewModel
    let exit: () -> Void

    init(mode: GameMode, stats: StatsStore, settings: AppSettings, practice: PracticePlan? = nil, exit: @escaping () -> Void) {
        _model = StateObject(wrappedValue: GameViewModel(mode: mode, stats: stats, settings: settings, practice: practice))
        self.exit = exit
    }
    private var en: Bool { settings.language == .english }
    private var animate: Bool { settings.animatedEffects && !reduceMotion }
    private var answered: Bool { model.selectedCode != nil }
    private var correct: Bool { model.selectedCode == model.question?.abb2 }

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    header.id("game-top")
                    status
                    if let country = model.question {
                        flagStage(country)
                        choices
                        if answered { answerNote(country).id("answer-note").transition(.opacity) }
                        else {
                            Label(en ? "Look closely. Trust your curiosity." : "仔細觀察，跟著你的直覺選擇。", systemImage: "eye")
                                .font(.caption).foregroundStyle(Atlas.muted).padding(.top, 4)
                        }
                    }
                }.padding(22).frame(maxWidth: 700).frame(maxWidth: .infinity)
            }
            .onChange(of: model.selectedCode) { _, value in
                if value != nil && model.isLearning {
                    withAnimation(animate ? .easeInOut(duration: 0.3) : nil) { proxy.scrollTo("answer-note", anchor: .bottom) }
                } else if value == nil {
                    withAnimation(animate ? .easeInOut(duration: 0.2) : nil) { proxy.scrollTo("game-top", anchor: .top) }
                }
            }
            }
            .allowsHitTesting(model.phase == .playing)
            .accessibilityHidden(model.phase != .playing)
            if model.phase == .paused { pauseOverlay.transition(.opacity) }
            if model.phase == .finished { resultOverlay.transition(.opacity) }
        }
        .foregroundStyle(.white)
        .animation(animate ? .spring(response: 0.4, dampingFraction: 0.8) : nil, value: model.selectedCode)
        .animation(animate ? .easeInOut(duration: 0.2) : nil, value: model.phase)
        .onChange(of: model.selectedCode) { _, code in
            guard let code else { return }
            AudioManager.shared.play(code == model.question?.abb2 ? .correct : .wrong)
        }
        .onChange(of: model.phase) { _, phase in
            AudioManager.shared.setDucked(phase != .playing)
            if phase == .finished, model.errorMessage == nil { AudioManager.shared.play(.complete) }
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.pause() } }
        .onDisappear { model.stop(); AudioManager.shared.setDucked(false) }
        #if DEBUG
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--preview-screen") {
                if args.contains("--preview-paused") { model.pause() }
                if args.contains("--preview-result"), let wrong = model.choices.first(where: { $0 != model.question }) {
                    model.select(wrong); model.finish()
                }
                if args.contains("--preview-answer"), let question = model.question { model.select(question) }
            }
        }
        #endif
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: model.isRetryingMistakes ? "arrow.triangle.2.circlepath" : model.mode.symbol)
                .foregroundStyle(model.mode.tint).font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: en ? "EXPEDITION IN PROGRESS" : "探索進行中", color: Atlas.muted)
                Text(model.isRetryingMistakes ? (en ? "Practice mistakes" : "本局錯題練習") : (model.practice?.title(settings.language) ?? model.mode.title(settings.language))).font(.headline)
            }
            Spacer()
            Button { model.togglePause() } label: {
                Image(systemName: "pause.fill").frame(width: 48, height: 48).background(.white.opacity(0.08), in: Circle())
            }.accessibilityLabel(en ? "Pause" : "暫停")
        }
    }

    private var status: some View {
        VStack(spacing: 14) {
            HStack {
                Metric(value: "\(model.correctAnswers)", label: en ? "Correct" : "答對題數")
                Metric(value: "\(model.streak)", label: en ? "In a row" : "連續答對", color: Atlas.gold)
                if model.mode == .twoLives && !model.isRetryingMistakes {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) { ForEach(0..<2) { index in Image(systemName: index < model.lives ? "heart.fill" : "heart").foregroundStyle(Atlas.coral) } }
                        Text(en ? "Lives" : "剩餘機會").font(.caption).foregroundStyle(Atlas.muted)
                    }.accessibilityLabel(en ? "\(model.lives) lives left" : "剩餘 \(model.lives) 次機會")
                } else if !model.isLearning {
                    Metric(value: "\(model.secondsRemaining)s", label: en ? "Remaining" : "剩餘時間", color: model.secondsRemaining <= 3 ? Atlas.coral : Atlas.blue)
                } else {
                    Metric(value: "\(model.totalQuestions)", label: en ? "Answered" : "已作答", color: Atlas.blue)
                }
            }
            if let limit = model.roundLimit {
                ProgressView(value: Double(model.totalQuestions), total: Double(max(1, limit))).tint(model.mode.tint)
                    .accessibilityLabel(en ? "Round progress" : "本局進度")
            } else if model.mode == .timedChallenge && !model.isRetryingMistakes {
                ProgressView(value: Double(model.secondsRemaining), total: 60).tint(model.mode.tint)
                    .accessibilityLabel(en ? "Time remaining" : "剩餘時間")
            }
        }.modifier(AtlasCard())
    }

    private func flagStage(_ country: Country) -> some View {
        VStack(spacing: 12) {
            HStack {
                Eyebrow(text: String(format: "FLAG / %03d", model.totalQuestions + (answered ? 0 : 1)))
                Spacer()
                Image(systemName: answered ? (correct ? "checkmark.seal.fill" : "lightbulb.fill") : "viewfinder")
                    .foregroundStyle(answered ? (correct ? Atlas.mint : Atlas.gold) : Atlas.muted)
                    .symbolEffect(.bounce, options: .nonRepeating, value: animate && answered)
            }
            FlagImage(code: country.abb2)
                .frame(height: 118).padding(.vertical, 6)
                .overlay { if answered && correct && animate { DiscoveryBurst().id(model.totalQuestions) } }
                .id(country.id).transition(.opacity)
                .accessibilityHidden(false)
                .accessibilityLabel(en ? "Flag to identify" : "待辨識的國旗")
            Text(en ? "Where in the world?" : "這面國旗，來自哪裡？")
                .font(.system(.title3, design: .rounded).bold())
            Text(en ? "CHOOSE ONE ANSWER" : "觀察圖案與配色，選出答案")
                .font(.system(.caption2, design: .monospaced)).tracking(1.5).foregroundStyle(Atlas.muted)
        }
        .modifier(AtlasCard(tint: answered ? (correct ? Atlas.mint : Atlas.gold) : .white))
    }

    private var choices: some View {
        VStack(spacing: 10) {
            ForEach(Array(model.choices.enumerated()), id: \.element.id) { index, country in
                let state = model.colorState(for: country)
                Button { model.select(country) } label: {
                    HStack(spacing: 14) {
                        Text(String(UnicodeScalar(65 + index)!)).font(.system(.caption, design: .monospaced).bold())
                            .frame(width: 32, height: 32).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        Text(country.name(for: settings.language)).font(.headline).multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if state == .correct || state == .wrong {
                            Image(systemName: state == .correct ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundStyle(state == .correct ? Atlas.mint : Atlas.coral)
                        }
                    }.padding(14).frame(minHeight: 62)
                        .background(answerColor(state).opacity(state == .idle ? 1 : 0.16), in: RoundedRectangle(cornerRadius: 19))
                        .overlay(RoundedRectangle(cornerRadius: 19).stroke(answerColor(state).opacity(state == .idle ? 0.6 : 0.8)))
                        .foregroundStyle(state == .disabled ? Atlas.muted : .white)
                }.buttonStyle(AtlasPressStyle(sound: nil)).disabled(answered || model.phase != .playing)
                    .accessibilityValue(state == .correct ? (en ? "Correct answer" : "正確答案") : state == .wrong ? (en ? "Incorrect choice" : "選錯了") : "")
            }
        }
    }

    private func answerColor(_ state: AnswerState) -> Color {
        switch state { case .idle, .disabled: Atlas.panel; case .correct: Atlas.mint; case .wrong: Atlas.coral }
    }

    private func answerNote(_ country: Country) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(correct ? (en ? "Another discovery!" : "又認識了一個地方！") : (en ? "A flag to remember" : "把這面國旗記下來"), systemImage: correct ? "sparkles" : "lightbulb")
                .font(.headline).foregroundStyle(correct ? Atlas.mint : Atlas.gold)
            Text("\(country.cn) · \(country.en)").font(.subheadline.bold())
            if model.isLearning {
                if let pair = model.comparison {
                    ComparisonCard(pair: pair, countries: model.comparisonCountries, initiallyRevealed: true)
                }
                if let due = stats.stats[country.abb2]?.nextReviewAt {
                    HStack {
                        Text(en ? "Next review" : "下次複習")
                        Text(due, style: .relative)
                    }.font(.caption).foregroundStyle(Atlas.blue)
                }
                Text(en ? "Notice the colors and shapes, then say its name before moving on." : "再看一次配色與圖案，試著說出名稱，再前往下一站。")
                    .font(.caption).foregroundStyle(Atlas.muted)
                Button { model.continueLearning() } label: {
                    HStack { Text(en ? "Continue journey" : "繼續旅程"); Spacer(); Image(systemName: "arrow.right") }
                }.buttonStyle(AtlasButtonStyle(filled: true))
            }
        }.frame(maxWidth: .infinity, alignment: .leading).modifier(AtlasCard(tint: Atlas.mint))
    }

    private var pauseOverlay: some View {
        modal {
            Image(systemName: "cup.and.saucer.fill").font(.system(size: 46)).foregroundStyle(Atlas.gold)
            Eyebrow(text: en ? "TAKE A BREATHER" : "旅途中，休息一下")
            Text(en ? "The world can wait." : "世界，等你準備好。")
                .font(.system(.title, design: .rounded).bold()).multilineTextAlignment(.center)
            Text(en ? "Your progress is right here." : "進度已保留，準備好就繼續出發。")
                .font(.subheadline).foregroundStyle(Atlas.muted)
            Button(en ? "Keep exploring" : "繼續探索") { model.togglePause() }.buttonStyle(AtlasButtonStyle(filled: true))
            Button(en ? "Start over" : "重新開始") { model.restart() }.buttonStyle(AtlasButtonStyle())
            Button(en ? "Finish & see results" : "結束並查看成果") { model.finish() }.buttonStyle(AtlasButtonStyle())
            Button(en ? "Back to home" : "返回首頁", action: exit).font(.subheadline).padding(12).foregroundStyle(Atlas.muted)
        }
    }

    private var resultOverlay: some View {
        modal {
            Image(systemName: model.errorMessage == nil ? "trophy.fill" : "safari")
                .font(.system(size: 48)).foregroundStyle(Atlas.gold)
                .symbolEffect(.bounce, options: .nonRepeating, value: animate && model.phase == .finished)
            Eyebrow(text: en ? "EXPEDITION REPORT" : "這一站的探索成果")
            Text(resultTitle).font(.system(.title, design: .rounded).bold()).multilineTextAlignment(.center)
            if model.errorMessage == nil {
                HStack {
                    Metric(value: "\(model.correctAnswers)/\(model.totalQuestions)", label: en ? "Correct" : "答對題數")
                    Metric(value: "\(Int(model.accuracy * 100))%", label: en ? "Accuracy" : "正確率", color: Atlas.gold)
                    Metric(value: "\(model.bestStreak)", label: en ? "Best streak" : "最高連答", color: Atlas.blue)
                }.padding(.vertical, 8)
                if !model.wrongAnswers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(en ? "Revisit these discoveries" : "再看一眼，就更熟悉了").font(.subheadline.bold())
                        ForEach(model.wrongAnswers) { answer in
                            HStack(spacing: 12) {
                                FlagImage(code: answer.country.abb2).frame(width: 54, height: 36)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(answer.country.name(for: settings.language)).font(.subheadline.bold())
                                    Text(answer.selected.map { (en ? "You chose: " : "你選了：") + $0.name(for: settings.language) } ?? (en ? "Time ran out" : "未及作答"))
                                        .font(.caption).foregroundStyle(Atlas.muted)
                                }
                                Spacer(minLength: 0)
                            }
                            if let selected = answer.selected,
                               let pair = FlagComparison.match(answer.country.abb2, selected.abb2) {
                                DisclosureGroup(en ? "Compare these flags" : "對照這兩面國旗") {
                                    ComparisonCard(pair: pair, countries: [answer.country, selected], initiallyRevealed: true)
                                }.font(.subheadline).tint(Atlas.gold)
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Button(en ? "Practice these mistakes" : "再練一次本局錯題") { model.retryMistakes() }.buttonStyle(AtlasButtonStyle(filled: true))
                }
                Button(en ? "New expedition" : "再開一局") { model.restart() }.buttonStyle(AtlasButtonStyle(filled: model.wrongAnswers.isEmpty))
            } else {
                Text(model.errorMessage == "review-empty"
                     ? (en ? "You are up to date. Explore new flags or return when your next review is due." : "到期題目已完成。可以先探索新國旗，或等下次複習時間再回來。")
                     : (en ? "Please restart the app and try again." : "請重新啟動 App 後再試一次。"))
                    .font(.subheadline).foregroundStyle(Atlas.muted).multilineTextAlignment(.center)
            }
            if model.errorMessage == "review-empty", let date = stats.nextReviewDate {
                HStack { Text(en ? "Next review" : "下次複習"); Text(date, style: .relative) }
                    .font(.subheadline).foregroundStyle(Atlas.gold)
            }
            Button(en ? "Back to home" : "返回首頁", action: exit).buttonStyle(AtlasButtonStyle())
        }
    }

    private var resultTitle: String {
        if model.errorMessage == "review-empty" { return en ? "All caught up." : "目前沒有到期的複習。" }
        if model.errorMessage != nil { return en ? "Unable to load flags" : "暫時無法載入國旗" }
        return en ? "A little more worldly." : "世界，又熟悉了一點。"
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Atlas.ink.opacity(0.97).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20, content: content)
                    .padding(26).frame(maxWidth: 520)
                    .background(Atlas.panel, in: RoundedRectangle(cornerRadius: 30))
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Atlas.mint.opacity(0.2)))
                    .padding(22).frame(maxWidth: .infinity)
            }.defaultScrollAnchor(.top)
        }
    }
}

#Preview { let settings = AppSettings(); ZStack { AppBackground(); GameView(mode: .endless, stats: StatsStore(), settings: settings) {} }.environmentObject(settings).environmentObject(StatsStore()) }
