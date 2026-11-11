import SwiftUI

/// A fixed-page entrance organized around intent, not a catalogue of game modes.
struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var intent: Intent = .teach
    @State private var showingFlashcards = false
    private let studyCountries = ((try? CountryRepository.load()) ?? []).sorted { $0.en < $1.en }
    let start: (GameMode) -> Void
    var open: (Sheet) -> Void = { _ in }
    var isVisible = true
    enum Sheet: Identifiable { case settings, records, journeys, comparisons, flags; var id: Self { self } }
    private enum Intent: CaseIterable { case teach, practice, play }

    private var animated: Bool {
        isVisible && settings.animatedEffects && !reduceMotion && scenePhase == .active && !showingFlashcards
    }

    private let ink = Atlas.text
    private let red = Atlas.gold

    private func text(_ en: String, _ zh: String, _ ja: String, _ ko: String) -> String {
        settings.language.text(en, zh, ja: ja, ko: ko)
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 700
            VStack(alignment: .leading, spacing: compact ? 16 : 24) {
                masthead
                intentPicker
                if let heading {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(heading.title).font(.system(size: compact ? 29 : 35, weight: .bold, design: .rounded))
                            .lineLimit(2).minimumScaleFactor(0.75)
                        Text(heading.subtitle).font(.system(size: 14)).foregroundStyle(ink.opacity(0.75))
                            .lineLimit(2).minimumScaleFactor(0.85)
                    }
                }
                Group {
                    switch intent {
                    case .teach: teaching(compact: compact)
                    case .practice: practice
                    case .play: challenges
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                footer
            }
            .padding(.horizontal, 24).padding(.vertical, compact ? 12 : 20)
            .frame(maxWidth: 650, maxHeight: .infinity).frame(maxWidth: .infinity)
        }
        .foregroundStyle(ink)
        #if DEBUG
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            guard args.contains("--preview-screen") else { return }
            if args.contains("--preview-home-practice") { intent = .practice }
            if args.contains("--preview-home-play") { intent = .play }
        }
        #endif
        .fullScreenCover(isPresented: $showingFlashcards, onDismiss: {
            AudioManager.shared.playMusic(.home)
        }) {
            FlagFlashcardsView(countries: studyCountries)
                .onAppear { AudioManager.shared.playMusic(.cards) }
        }
    }

    private var masthead: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Image(systemName: "flag.fill").font(.system(size: 19))
                    .foregroundStyle(Atlas.onAccent).frame(width: 42, height: 42)
                    .background(Atlas.yellow, in: RoundedRectangle(cornerRadius: 15))
                    .rotationEffect(.degrees(-8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.language.appName)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.75)
                    Text(text("Little flags. Big world.", "小小國旗，大大世界", "小さな国旗、大きな世界", "작은 국기, 커다란 세상"))
                        .font(.system(size: 11)).foregroundStyle(Atlas.muted)
                }
            }
            Spacer(minLength: 0)
            Button { open(.settings) } label: {
                Image(systemName: "slider.horizontal.3").font(.system(size: 18)).frame(width: 44, height: 44)
                    .background(Atlas.panel, in: Circle())
            }.buttonStyle(.plain).accessibilityLabel(text("Settings", "設定", "設定", "설정"))
        }
    }

    private var intentPicker: some View {
        HStack(spacing: 6) {
            ForEach(Intent.allCases, id: \.self) { choice in
                Button { intent = choice } label: {
                    Text(intentTitle(choice)).font(.system(size: 13, weight: intent == choice ? .bold : .medium, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.75)
                        .foregroundStyle(intent == choice ? Atlas.onAccent : Atlas.muted)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(intent == choice ? Atlas.yellow : Atlas.panel.opacity(0.85), in: RoundedRectangle(cornerRadius: 17))
                        .shadow(color: Atlas.yellow.opacity(intent == choice ? 0.45 : 0), radius: 12, y: 4)
                }.buttonStyle(.plain)
                    .accessibilityAddTraits(intent == choice ? .isSelected : [])
            }
        }
    }

    private func intentTitle(_ choice: Intent) -> String {
        switch choice {
        case .teach: text("Teach with cards", "圖卡教孩子", "カードで教える", "카드로 가르치기")
        case .practice: text("Practice", "自己練習", "自分で練習", "혼자 연습하기")
        case .play: text("Play a quiz", "挑戰遊戲", "クイズに挑戦", "퀴즈 도전")
        }
    }

    private var heading: (title: String, subtitle: String)? {
        switch intent {
        case .teach: return nil
        case .practice:
            return (text("Take your time.\nGet to know the world.", "慢慢認識，\n把世界記在心裡。", "自分のペースで、\n世界を覚えよう。", "천천히 배우며,\n세계를 기억해요."),
                    text("Untimed practice, with room to learn after each answer.", "沒有時間壓力，每答一題都能停下來學。", "時間制限なし。一問ずつじっくり学べます。", "시간 제한 없이 한 문제씩 천천히 배워요."))
        case .play:
            return (text("Know your flags?\nPut it to the test.", "認得多少面？\n來一場小挑戰。", "いくつ分かるかな？\nクイズに挑戦。", "얼마나 알고 있나요?\n퀴즈에 도전해요."),
                    text("Pick a rule. Your round starts when you tap.", "選一種規則，點一下就開始。", "ルールを選んでタップするとスタート。", "규칙을 고르고 누르면 바로 시작해요."))
        }
    }

    private func teaching(compact: Bool) -> some View {
        VStack(spacing: compact ? 12 : 20) {
            GeometryReader { proxy in
                let diameter = max(0, min(proxy.size.width - 28, proxy.size.height - 16, 268))
                HomeGlobe(diameter: diameter, animated: animated)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }.accessibilityHidden(true)
            Text(text("Large flags · Country names · Swipe to the next card", "大幅國旗  ·  中英文國名  ·  左右翻卡", "大きな国旗  ·  国名  ·  スワイプで次へ", "큰 국기  ·  나라 이름  ·  옆으로 넘기기"))
                .font(.system(size: 11)).foregroundStyle(Atlas.muted).lineLimit(1).minimumScaleFactor(0.75)
            Button { showingFlashcards = true } label: {
                HStack {
                    Image(systemName: "rectangle.on.rectangle.angled")
                    Text(text("Open teaching cards", "圖卡教學", "学習カードを開く", "학습 카드 열기"))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").font(.system(size: 18, weight: .bold))
                }.font(.system(size: 16, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.75)
                    .padding(.horizontal, 20).frame(height: 58)
                    .foregroundStyle(Atlas.onAccent)
                    .background {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(LinearGradient(colors: [Color(red: 1, green: 0.96, blue: 0.47), Atlas.yellow],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay {
                                if animated {
                                    TeachingButtonReflection()
                                        .clipShape(RoundedRectangle(cornerRadius: 22))
                                }
                            }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.45), lineWidth: 1))
                    .shadow(color: Atlas.yellow.opacity(0.3), radius: 18, y: 7)
            }.buttonStyle(.plain)
        }
    }

    private var practice: some View {
        VStack(spacing: 10) {
            route("01", text("Guess the country", "看國旗猜國家", "国名を当てよう", "나라 이름 맞히기"), text("Untimed · Continue when you are ready", "不限時，答完再繼續", "時間制限なし・自分のペースで", "시간 제한 없이 한 문제씩")) { start(.endless) }
            route("02", text("Explore by region", "選一洲慢慢學", "地域ごとに学ぶ", "지역별로 배우기"), text("Short rounds from six regions", "六大洲，每次一小回合", "6 地域の短い練習", "6개 지역의 짧은 연습")) { open(.journeys) }
            route("03", text("Compare similar flags", "分清楚相似國旗", "似た国旗を見分ける", "비슷한 국기 구별하기"), text("Compare them side by side", "並排看，找出不一樣的地方", "並べて違いを見つけよう", "나란히 놓고 차이 찾기")) { open(.comparisons) }
            route("04", text("Review learned flags", "複習學過的國旗", "学んだ国旗を復習", "배운 국기 복습하기"), text("Revisit flags when they are due", "依照練習紀錄，回顧到期國旗", "復習の時期に振り返ろう", "복습할 때가 된 국기를 다시 보기")) { start(.review) }
        }
    }

    private var challenges: some View {
        VStack(spacing: 10) {
            route("01", text("Time attack", "極限倒數", "タイムアタック", "타임 어택"), text("60 seconds to get as many right as you can", "60 秒內，看看能答對幾題", "60 秒で何問正解できるかな", "60초 동안 최대한 많이 맞히기")) { start(.timedChallenge) }
            route("02", text("Speed round", "閃電快答", "スピードラウンド", "스피드 라운드"), text("20 flags · 5 seconds each", "20 題，每題只有 5 秒", "20 問・一問につき 5 秒", "20문제 · 문제당 5초")) { start(.speedRound) }
            route("03", text("Two lives", "雙心生存", "ライフ 2 つ", "기회 두 번"), text("Your second mistake ends the round", "答錯兩次就結束，你能撐多久？", "2 回間違えると終了", "두 번 틀리면 종료")) { start(.twoLives) }
        }
    }

    private func route(_ number: String, _ title: String, _ detail: String, action: @escaping () -> Void) -> some View {
        let badge = number == "01" ? Atlas.yellow : number == "02" ? Atlas.cardMint : Atlas.cardBlue
        return Button(action: action) {
            HStack(spacing: 14) {
                Text(number).font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Atlas.onAccent).frame(width: 38, height: 38)
                    .background(badge, in: RoundedRectangle(cornerRadius: 13))
                    .shadow(color: badge.opacity(0.7), radius: 8)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.system(size: 17, weight: .bold))
                    Text(detail).font(.system(size: 12)).foregroundStyle(ink.opacity(0.65))
                }.lineLimit(1).minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.system(size: 16)).foregroundStyle(red)
            }.padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 56, maxHeight: .infinity, alignment: .leading)
                .background(Atlas.panel.opacity(0.9), in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(
                    LinearGradient(colors: [badge.opacity(0.9), Atlas.line.opacity(0.3)], startPoint: .leading, endPoint: .trailing), lineWidth: 1.2))
                .shadow(color: badge.opacity(0.22), radius: 14, y: 6)
                .contentShape(RoundedRectangle(cornerRadius: 24))
        }.buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Button { open(.flags) } label: {
                Label(text("Flag collection", "查國旗圖鑑", "国旗図鑑", "국기 도감"), systemImage: "book.closed")
            }
            Spacer()
            Button { open(.records) } label: {
                Label(text("My progress", "學習紀錄", "学習記録", "학습 기록"), systemImage: "chart.bar.xaxis")
            }
        }.font(.system(size: 12, weight: .medium)).buttonStyle(.plain)
            .frame(height: 44).padding(.top, 6)
            .foregroundStyle(Atlas.muted)
    }
}

private struct TeachingButtonReflection: View {
    @State private var swept = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            LinearGradient(colors: [.clear, .white.opacity(0.78), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 68, height: geometry.size.height * 2)
                .rotationEffect(.degrees(24))
                .position(x: swept ? width + 64 : -64, y: geometry.size.height / 2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            do {
                try await Task.sleep(for: .seconds(5))
                while !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 0.55)) { swept = true }
                    try await Task.sleep(for: .milliseconds(550))
                    swept = false
                    try await Task.sleep(for: .milliseconds(4450))
                }
            } catch { return }
        }
    }
}

private struct HomeGlobe: View {
    let diameter: CGFloat
    let animated: Bool
    @State private var flagBatch = 0

    private static let flagBatches = [
        ["TW", "BR", "CA", "KR", "FR", "AU"],
        ["JP", "AR", "SE", "ZA", "MX", "NZ"],
        ["KE", "PT", "CL", "IN", "JM", "FJ"]
    ]
    private static let flagPositions: [CGPoint] = [
        .init(x: -0.36, y: -0.33), .init(x: 0.39, y: -0.29),
        .init(x: -0.47, y: -0.01), .init(x: 0.47, y: 0.04),
        .init(x: -0.35, y: 0.31), .init(x: 0.34, y: 0.35)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated)) { timeline in
            let time = animated ? timeline.date.timeIntervalSinceReferenceDate : 0
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Atlas.blue.opacity(0.32), Atlas.mint.opacity(0.12), .clear],
                                         center: .center, startRadius: diameter * 0.12, endRadius: diameter * 0.5))
                Circle()
                    .stroke(Atlas.blue.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 8]))
                    .frame(width: diameter * 0.82, height: diameter * 0.82)
                    .rotationEffect(.degrees(time.truncatingRemainder(dividingBy: 36) * 10))
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: diameter * 0.66, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [Atlas.mint, Atlas.blue],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Atlas.blue.opacity(0.5), radius: 18)
                ForEach(Self.flagPositions.indices, id: \.self) { index in
                    let position = Self.flagPositions[index]
                    let code = Self.flagBatches[flagBatch][index]
                    let phase = time * 0.5 + Double(index) * 1.7
                    FlagImage(code: code)
                        .frame(width: diameter * 0.13, height: diameter * 0.09)
                        .padding(diameter * 0.02)
                        .background(Atlas.panel, in: RoundedRectangle(cornerRadius: diameter * 0.032))
                        .shadow(color: Atlas.mint.opacity(0.35), radius: 8)
                        .id(code)
                        .transition(.scale(scale: 0.55).combined(with: .opacity))
                        .rotationEffect(.degrees(Double(index % 3 - 1) * 12 + sin(phase) * 4))
                        .offset(x: position.x * diameter, y: (position.y + sin(phase) * 0.02) * diameter)
                }
            }
            .frame(width: diameter, height: diameter)
        }
        .task(id: animated) {
            guard animated else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(3.5)) } catch { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    flagBatch = (flagBatch + 1) % Self.flagBatches.count
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview { AppPreview { ZStack { AppBackground(style: .home); HomeView { _ in } } } }
