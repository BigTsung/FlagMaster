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
    private var animate: Bool { settings.animatedEffects && !reduceMotion }
    private var answered: Bool { model.selectedCode != nil }
    private var correct: Bool { model.selectedCode == model.question?.abb2 }

    private var musicTrack: AudioTrack {
        if model.isRetryingMistakes { return .review }
        switch model.practice {
        case .region: return .region
        case .comparison: return .comparison
        case nil: break
        }
        switch model.mode {
        case .endless: return .learning
        case .timedChallenge: return .game
        case .speedRound: return .speedRound
        case .twoLives: return .twoLives
        case .review: return .review
        }
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: geometry.size.height < 720 ? 9 : 14) {
                    header
                    status
                    if let country = model.question {
                        Spacer(minLength: 0)
                        flagStage(country, compact: geometry.size.height < 680)
                        Spacer(minLength: 0)
                        choices(compact: geometry.size.height < 680)
                        if !answered {
                            Label(settings.language.text("LOCK IN YOUR ANSWER", "鎖定答案，拿下這一題！", ja: "答えを選ぼう！", ko: "정답을 골라 보세요!"), systemImage: "scope")
                                .font(.caption).foregroundStyle(Atlas.muted)
                        }
                    }
                }.padding(.horizontal, 20).padding(.vertical, 10).frame(maxWidth: 700, maxHeight: .infinity).frame(maxWidth: .infinity)
            }
            .allowsHitTesting(model.phase == .playing)
            .accessibilityHidden(model.phase != .playing)
            if answered, model.isLearning, let country = model.question { learningFeedbackOverlay(country).transition(.move(edge: .bottom).combined(with: .opacity)) }
            if model.phase == .paused { pauseOverlay.transition(.opacity) }
            if model.phase == .finished { resultOverlay.transition(.opacity) }
        }
        .foregroundStyle(Atlas.text)
        .animation(animate ? .spring(response: 0.4, dampingFraction: 0.8) : nil, value: model.selectedCode)
        .animation(animate ? .easeInOut(duration: 0.2) : nil, value: model.phase)
        .onAppear { updateGameMusic() }
        .onChange(of: musicTrack) { _, _ in updateGameMusic() }
        .onChange(of: model.soundEvent) { _, event in
            if let event { AudioManager.shared.play(event.effect) }
        }
        .onChange(of: model.phase) { _, phase in
            if phase == .paused || phase == .playing { AudioManager.shared.stopEffects() }
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.pause() } }
        .onDisappear { model.stop(); AudioManager.shared.stopEffects() }
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

    private func updateGameMusic() {
        AudioManager.shared.playMusic(musicTrack)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: model.isRetryingMistakes ? "arrow.triangle.2.circlepath" : model.mode.symbol)
                .foregroundStyle(model.mode.tint).font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: settings.language.text("CHALLENGE LIVE", "挑戰進行中", ja: "チャレンジ中", ko: "도전 중"), color: Atlas.mint)
                Text(model.isRetryingMistakes ? (settings.language.text("Practice mistakes", "本局錯題練習", ja: "間違えた問題を練習", ko: "틀린 문제 연습")) : (model.practice?.title(settings.language) ?? model.mode.title(settings.language))).font(.headline)
            }
            Spacer()
            Button { model.togglePause() } label: {
                Image(systemName: "pause.fill").frame(width: 44, height: 44).modifier(GamePanel(tint: Atlas.accent, radius: 14))
            }.accessibilityLabel(settings.language.text("Pause", "暫停", ja: "一時停止", ko: "일시 정지"))
        }
    }

    private var status: some View {
        VStack(spacing: 14) {
            HStack {
                Metric(value: "\(model.correctAnswers)", label: settings.language.text("Correct", "答對題數", ja: "正解数", ko: "정답 수"))
                Metric(value: "\(model.streak)×", label: settings.language.text("COMBO", "連續答對", ja: "コンボ", ko: "콤보"), color: Atlas.gold)
                if model.mode == .twoLives && !model.isRetryingMistakes {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) { ForEach(0..<2) { index in Image(systemName: index < model.lives ? "heart.fill" : "heart").foregroundStyle(Atlas.coral) } }
                        Text(settings.language.text("Lives", "剩餘機會", ja: "残りライフ", ko: "남은 기회")).font(.caption).foregroundStyle(Atlas.muted)
                    }.accessibilityLabel(settings.language.text("\(model.lives) lives left", "剩餘 \(model.lives) 次機會", ja: "残り \(model.lives) 回", ko: "남은 기회 \(model.lives)번"))
                } else if !model.isLearning {
                    Metric(value: settings.language.text("\(model.secondsRemaining)s", "\(model.secondsRemaining) 秒", ja: "\(model.secondsRemaining) 秒", ko: "\(model.secondsRemaining)초"), label: settings.language.text("Remaining", "剩餘時間", ja: "残り時間", ko: "남은 시간"), color: model.secondsRemaining <= 3 ? Atlas.coral : Atlas.blue)
                } else {
                    Metric(value: "\(model.totalQuestions)", label: settings.language.text("Answered", "已作答", ja: "回答済み", ko: "응답 수"), color: Atlas.blue)
                }
            }
            if let limit = model.roundLimit {
                ProgressView(value: Double(model.totalQuestions), total: Double(max(1, limit))).tint(model.mode.tint)
                    .accessibilityLabel(settings.language.text("Round progress", "本局進度", ja: "ラウンドの進行状況", ko: "라운드 진행 상황"))
            } else if model.mode == .timedChallenge && !model.isRetryingMistakes {
                ProgressView(value: Double(model.secondsRemaining), total: 60).tint(model.mode.tint)
                    .accessibilityLabel(settings.language.text("Time remaining", "剩餘時間", ja: "残り時間", ko: "남은 시간"))
            }
        }.modifier(AtlasCard(tint: Atlas.accent))
    }

    private func flagStage(_ country: Country, compact: Bool) -> some View {
        VStack(spacing: 12) {
            HStack {
                let flagLabel = settings.language.text("FLAG", "國旗", ja: "国旗", ko: "국기")
                let questionNumber = String(format: "%03d", model.totalQuestions + (answered ? 0 : 1))
                Eyebrow(text: "\(flagLabel) / \(questionNumber)")
                Spacer()
                Image(systemName: answered ? (correct ? "checkmark.seal.fill" : "lightbulb.fill") : "viewfinder")
                    .foregroundStyle(answered ? (correct ? Atlas.mint : Atlas.gold) : Atlas.muted)
                    .symbolEffect(.bounce, options: .nonRepeating, value: animate && answered)
            }
            FlagImage(code: country.abb2)
                .frame(height: compact ? 90 : 140).padding(.vertical, compact ? 4 : 12)
                .shadow(color: Atlas.blue.opacity(0.3), radius: 20, y: 8)
                .overlay { if answered && correct && animate { DiscoveryBurst().id(model.totalQuestions) } }
                .id(country.id).transition(.opacity)
                .accessibilityHidden(false)
                .accessibilityLabel(settings.language.text("Flag to identify", "待辨識的國旗", ja: "問題の国旗", ko: "맞혀야 할 국기"))
            Text(answered ? (correct ? (settings.language.text("PERFECT!", "漂亮！答對了", ja: "正解！", ko: "정답!")) : (settings.language.text("TRY AGAIN!", "再接再厲！", ja: "次もがんばろう！", ko: "다음 문제에 도전!"))) : (settings.language.text("NAME THIS FLAG", "這是哪個國家？", ja: "どこの国旗？", ko: "어느 나라의 국기일까요?")))
                .font(.system(.title3, design: .rounded).bold())
            if !compact {
                Text(settings.language.text("CHOOSE ONE ANSWER", "觀察圖案與配色，選出答案", ja: "模様と色を見て答えを選ぼう", ko: "무늬와 색을 보고 정답을 고르세요"))
                    .font(.system(.caption2, design: .monospaced)).tracking(1.5).foregroundStyle(Atlas.muted)
            }
        }
        .modifier(AtlasCard(tint: answered ? (correct ? Atlas.mint : Atlas.coral) : Atlas.blue))
        .rotationEffect(.degrees(answered && !correct && animate ? -1.5 : 0))
    }

    private func choices(compact: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(model.choices.enumerated()), id: \.element.id) { index, country in
                let state = model.colorState(for: country)
                Button { model.select(country) } label: {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text(String(UnicodeScalar(65 + index)!)).font(.system(.caption, design: .rounded).weight(.black))
                                .foregroundStyle(Atlas.gold).frame(width: 24, height: 24).background(Atlas.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                            Spacer()
                            Image(systemName: state == .correct ? "checkmark.circle.fill" : state == .wrong ? "xmark.circle.fill" : "plus")
                                .font(.caption).foregroundStyle(state == .correct ? Atlas.mint : state == .wrong ? Atlas.coral : Atlas.muted)
                        }
                        Text(country.name(for: settings.language)).font(.headline).multilineTextAlignment(.leading)
                            .lineLimit(2).minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(14).frame(maxWidth: .infinity, minHeight: compact ? 90 : 100, alignment: .topLeading)
                        .modifier(GamePanel(tint: state == .idle || state == .disabled ? Atlas.accent : answerColor(state), radius: 19))
                        .foregroundStyle(state == .disabled ? Atlas.muted : Atlas.text)
                }.buttonStyle(AtlasPressStyle(sound: nil)).disabled(answered || model.phase != .playing)
                    .accessibilityValue(state == .correct ? (settings.language.text("Correct answer", "正確答案", ja: "正解", ko: "정답")) : state == .wrong ? (settings.language.text("Incorrect choice", "選錯了", ja: "不正解", ko: "오답")) : "")
            }
        }
    }

    private func answerColor(_ state: AnswerState) -> Color {
        switch state { case .idle, .disabled: Atlas.panel; case .correct: Atlas.mint; case .wrong: Atlas.coral }
    }

    private func answerNote(_ country: Country) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(correct ? (settings.language.text("Another discovery!", "又認識了一個地方！", ja: "新しい発見！", ko: "새로운 발견!")) : (settings.language.text("A flag to remember", "把這面國旗記下來", ja: "この国旗を覚えよう", ko: "이 국기를 기억해 보세요")), systemImage: correct ? "sparkles" : "lightbulb")
                .font(.headline).foregroundStyle(correct ? Atlas.mint : Atlas.gold)
            Text("\(country.name(for: settings.language == .english ? .traditionalChinese : settings.language)) · \(country.en)").font(.subheadline.bold())
            if model.isLearning {
                if let pair = model.comparison {
                    ComparisonCard(pair: pair, countries: model.comparisonCountries, initiallyRevealed: true)
                }
                if let due = stats.stats[country.abb2]?.nextReviewAt {
                    HStack {
                        Text(settings.language.text("Next review", "下次複習", ja: "次の復習", ko: "다음 복습"))
                        Text(due, style: .relative)
                    }.font(.caption).foregroundStyle(Atlas.blue)
                }
                Text(settings.language.text("Notice the colors and shapes, then say its name before moving on.", "再看一次配色與圖案，試著說出名稱，再前往下一站。", ja: "色と形をよく見て、名前を言ってから次に進もう。", ko: "색과 모양을 살펴보고 이름을 말한 다음 넘어가세요."))
                    .font(.caption).foregroundStyle(Atlas.muted)
                Button { model.continueLearning() } label: {
                    HStack { Text(settings.language.text("Continue journey", "繼續旅程", ja: "次へ進む", ko: "다음으로")); Spacer(); Image(systemName: "arrow.right") }
                }.buttonStyle(AtlasButtonStyle(filled: true))
                    .modifier(ActionHint())
            }
        }.frame(maxWidth: .infinity, alignment: .leading).modifier(AtlasCard(tint: Atlas.mint))
    }

    private func learningFeedbackOverlay(_ country: Country) -> some View {
        ZStack {
            Color.black.opacity(0.68).ignoresSafeArea()
            answerNote(country).padding(20).frame(maxWidth: 560)
        }
    }

    private var pauseOverlay: some View {
        modal {
            Image(systemName: "pause.circle.fill").font(.system(size: 60)).foregroundStyle(Atlas.gold).shadow(color: Atlas.gold.opacity(0.4), radius: 20)
            Eyebrow(text: settings.language.text("PAUSED", "已暫停", ja: "一時停止中", ko: "일시 정지 중"), color: Atlas.gold)
            Text(settings.language.text("Ready for the next round?", "休息一下，再戰一回。", ja: "ひと休みして、また挑戦しよう。", ko: "잠시 쉬고 다시 도전해 보세요."))
                .font(.system(.title, design: .rounded).bold()).multilineTextAlignment(.center)
            Text(settings.language.text("Your progress is right here.", "進度已保留，準備好就繼續出發。", ja: "準備ができたら続きから再開できます。", ko: "준비되면 이어서 진행할 수 있어요."))
                .font(.subheadline).foregroundStyle(Atlas.muted)
            Button(settings.language.text("Keep exploring", "繼續探索", ja: "再開", ko: "계속하기")) { model.togglePause() }.buttonStyle(AtlasButtonStyle(filled: true))
            Button(settings.language.text("Start over", "重新開始", ja: "最初から", ko: "처음부터 다시")) { model.restart() }.buttonStyle(AtlasButtonStyle())
            Button(settings.language.text("Finish & see results", "結束並查看成果", ja: "終了して結果を見る", ko: "종료하고 결과 보기")) { model.finish() }.buttonStyle(AtlasButtonStyle())
            Button(settings.language.text("Back to home", "返回首頁", ja: "ホームに戻る", ko: "홈으로"), action: exit).font(.subheadline).padding(12).foregroundStyle(Atlas.muted)
        }
    }

    private var resultOverlay: some View {
        modal {
            Image(systemName: model.errorMessage == nil ? "trophy.fill" : "safari")
                .font(.system(size: 48)).foregroundStyle(Atlas.gold)
                .symbolEffect(.bounce, options: .nonRepeating, value: animate && model.phase == .finished)
            Eyebrow(text: settings.language.text("CHALLENGE COMPLETE", "挑戰完成", ja: "チャレンジ完了", ko: "도전 완료"), color: Atlas.gold)
            Text(resultTitle).font(.system(.title, design: .rounded).bold()).multilineTextAlignment(.center)
            if model.errorMessage == nil {
                HStack {
                    Metric(value: "\(model.correctAnswers)/\(model.totalQuestions)", label: settings.language.text("Correct", "答對題數", ja: "正解数", ko: "정답 수"))
                    Metric(value: "\(Int(model.accuracy * 100))%", label: settings.language.text("Accuracy", "正確率", ja: "正答率", ko: "정답률"), color: Atlas.gold)
                    Metric(value: "\(model.bestStreak)", label: settings.language.text("Best streak", "最高連答", ja: "最高連続正解", ko: "최고 연속 정답"), color: Atlas.blue)
                }.padding(.vertical, 8)
                if !model.wrongAnswers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(settings.language.text("Revisit these discoveries", "再看一眼，就更熟悉了", ja: "もう一度見て覚えよう", ko: "다시 보고 익혀 보세요")).font(.subheadline.bold())
                        ForEach(model.wrongAnswers.prefix(2)) { answer in
                            HStack(spacing: 12) {
                                FlagImage(code: answer.country.abb2).frame(width: 54, height: 36)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(answer.country.name(for: settings.language)).font(.subheadline.bold())
                                    Text(answer.selected.map { (settings.language.text("You chose: ", "你選了：", ja: "選んだ答え：", ko: "선택한 답: ")) + $0.name(for: settings.language) } ?? (settings.language.text("Time ran out", "未及作答", ja: "時間切れ", ko: "시간 초과")))
                                        .font(.caption).foregroundStyle(Atlas.muted)
                                }
                                Spacer(minLength: 0)
                            }
                            if let selected = answer.selected,
                               let pair = FlagComparison.match(answer.country.abb2, selected.abb2) {
                                Text(pair.clue(settings.language)).font(.caption).foregroundStyle(Atlas.gold).lineLimit(2)
                            }
                        }
                        if model.wrongAnswers.count > 2 {
                            Text(settings.language.text("+ \(model.wrongAnswers.count - 2) more in your passport", "其餘 \(model.wrongAnswers.count - 2) 面已記錄在探索護照", ja: "ほか \(model.wrongAnswers.count - 2) 件はパスポートに記録済み", ko: "나머지 \(model.wrongAnswers.count - 2)개는 탐험 여권에 기록됐어요"))
                                .font(.caption).foregroundStyle(Atlas.muted)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Button(settings.language.text("Practice these mistakes", "再練一次本局錯題", ja: "間違えた問題をもう一度", ko: "틀린 문제 다시 풀기")) { model.retryMistakes() }.buttonStyle(AtlasButtonStyle(filled: true))
                }
                Button(settings.language.text("New expedition", "再開一局", ja: "もう一度挑戦", ko: "다시 도전")) { model.restart() }.buttonStyle(AtlasButtonStyle(filled: model.wrongAnswers.isEmpty))
            } else {
                Text(model.errorMessage == "review-empty"
                     ? (settings.language.text("You are up to date. Explore new flags or return when your next review is due.", "到期題目已完成。可以先探索新國旗，或等下次複習時間再回來。", ja: "復習は完了です。新しい国旗を探すか、次の復習までお待ちください。", ko: "복습을 마쳤어요. 새 국기를 탐험하거나 다음 복습 시간에 돌아오세요."))
                     : (settings.language.text("Please restart the app and try again.", "請重新啟動 App 後再試一次。", ja: "アプリを再起動して、もう一度お試しください。", ko: "앱을 다시 시작한 뒤 시도해 주세요.")))
                    .font(.subheadline).foregroundStyle(Atlas.muted).multilineTextAlignment(.center)
            }
            if model.errorMessage == "review-empty", let date = stats.nextReviewDate {
                HStack { Text(settings.language.text("Next review", "下次複習", ja: "次の復習", ko: "다음 복습")); Text(date, style: .relative) }
                    .font(.subheadline).foregroundStyle(Atlas.gold)
            }
            Button(settings.language.text("Back to home", "返回首頁", ja: "ホームに戻る", ko: "홈으로"), action: exit).buttonStyle(AtlasButtonStyle())
        }
    }

    private var resultTitle: String {
        if model.errorMessage == "review-empty" { return settings.language.text("All caught up.", "目前沒有到期的複習。", ja: "今すぐ復習する国旗はありません。", ko: "지금 복습할 국기가 없어요.") }
        if model.errorMessage != nil { return settings.language.text("Unable to load flags", "暫時無法載入國旗", ja: "国旗を読み込めません", ko: "국기를 불러올 수 없어요") }
        return model.accuracy >= 0.8 ? (settings.language.text("OUTSTANDING!", "實力超群！", ja: "すばらしい！", ko: "훌륭해요!")) : (settings.language.text("KEEP LEVELING UP!", "繼續突破！", ja: "さらに腕を磨こう！", ko: "계속 실력을 키워 봐요!"))
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Atlas.ink.opacity(0.97).ignoresSafeArea()
            VStack(spacing: 14, content: content)
                .padding(22).frame(maxWidth: 520)
                .modifier(GamePanel(tint: Atlas.gold, radius: 30))
                .padding(18).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview { let settings = AppSettings(); ZStack { AppBackground(); GameView(mode: .endless, stats: StatsStore(), settings: settings) {} }.environmentObject(settings).environmentObject(StatsStore()).preferredColorScheme(.dark) }
