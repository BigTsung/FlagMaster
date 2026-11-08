import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var orbit = false
    let start: (GameMode) -> Void
    var open: (Sheet) -> Void = { _ in }
    enum Sheet: Identifiable { case settings, records, journeys, comparisons, flags; var id: Self { self } }
    private var animated: Bool { settings.animatedEffects && !reduceMotion && scenePhase == .active }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 730
            VStack(spacing: compact ? 12 : 18) {
                playerBar
                hero(compact: compact, tiny: geometry.size.height < 650)
                VStack(spacing: compact ? 12 : 18) {
                    HStack {
                        Label(settings.language.text("CHOOSE YOUR CHALLENGE", "選擇你的挑戰", ja: "チャレンジを選ぼう", ko: "도전을 선택하세요"), systemImage: "bolt.shield.fill")
                            .font(.system(size: 11, weight: .black, design: .rounded)).tracking(1)
                        Spacer()
                        Text(settings.language.text("4 MODES", "4 種挑戰", ja: "4 つのモード", ko: "4가지 모드")).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Atlas.muted)
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        mode(title: settings.language.text("Time attack", "極限倒數", ja: "タイムアタック", ko: "타임 어택"), detail: settings.language.text("60 SECOND RUSH", "60 秒 · 挑戰極限", ja: "60 秒で限界に挑戦", ko: "60초 동안 한계에 도전"), icon: "timer", tint: Atlas.gold, compact: compact) { start(.timedChallenge) }
                        mode(title: settings.language.text("Speed run", "閃電快答", ja: "スピードラン", ko: "스피드런"), detail: settings.language.text("20 FLAGS · 5s EACH", "20 題 · 每題 5 秒", ja: "20 問・各 5 秒", ko: "20문제 · 문제당 5초"), icon: "bolt.fill", tint: Atlas.blue, compact: compact) { start(.speedRound) }
                        mode(title: settings.language.text("Survival", "雙心生存", ja: "サバイバル", ko: "서바이벌"), detail: settings.language.text("ONLY TWO LIVES", "兩顆心 · 撐到最後", ja: "ライフは 2 つ", ko: "기회는 단 두 번"), icon: "heart.fill", tint: Atlas.coral, compact: compact) { start(.twoLives) }
                        mode(title: settings.language.text("World tour", "世界闖關", ja: "世界ツアー", ko: "세계 투어"), detail: settings.language.text("CONQUER 6 REGIONS", "六大洲 · 逐區挑戰", ja: "6 地域に挑戦", ko: "6개 지역에 도전"), icon: "globe.asia.australia.fill", tint: Atlas.mint, compact: compact) { open(.journeys) }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                HStack(spacing: 8) {
                    dock(settings.language.text("Collection", "國旗圖鑑", ja: "国旗図鑑", ko: "국기 도감"), icon: "square.stack.3d.up.fill", tint: Atlas.blue) { open(.flags) }
                    dock(settings.language.text("Training", "辨識特訓", ja: "見分ける練習", ko: "구별 훈련"), icon: "scope", tint: Atlas.coral) { open(.comparisons) }
                    dock(settings.language.text("Review", "複習挑戰", ja: "復習", ko: "복습"), icon: "arrow.clockwise", tint: Atlas.mint) { start(.review) }
                    dock(settings.language.text("Records", "戰績", ja: "記録", ko: "기록"), icon: "trophy.fill", tint: Atlas.gold) { open(.records) }
                }.padding(10).modifier(GamePanel(tint: Atlas.violet, radius: 24))
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
            .frame(maxWidth: 700, maxHeight: .infinity).frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
        .background {
            if animated {
                HomeMotionBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private var playerBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "flag.checkered").font(.title3.bold()).foregroundStyle(Atlas.gold)
                .frame(width: 42, height: 42).modifier(GamePanel(tint: Atlas.gold, radius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text(settings.language.text("FLAG CHALLENGER", "國旗挑戰者", ja: "国旗チャレンジャー", ko: "국기 도전자")).font(.system(size: 12, weight: .black, design: .rounded))
                Text(settings.language.text("\(stats.stats.count) flags discovered", "已探索 \(stats.stats.count) 面國旗", ja: "\(stats.stats.count) 面の国旗を発見", ko: "국기 \(stats.stats.count)개 발견"))
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(Atlas.muted)
            }
            Spacer()
            Button { open(.settings) } label: {
                Image(systemName: "gearshape.fill").font(.title3).frame(width: 44, height: 44)
                    .modifier(GamePanel(tint: Atlas.violet, radius: 14))
            }.buttonStyle(AtlasPressStyle(sound: nil)).accessibilityLabel(settings.language.text("Settings", "設定", ja: "設定", ko: "설정"))
        }
    }

    private func hero(compact: Bool, tiny: Bool) -> some View {
        VStack(spacing: compact ? 8 : 12) {
            ZStack {
                Circle().fill(RadialGradient(colors: [Atlas.violet.opacity(0.7), .clear], center: .center, startRadius: 10, endRadius: 115))
                    .frame(width: 230, height: 230)
                Circle().stroke(Atlas.blue.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 8]))
                    .frame(width: 155, height: 155).rotationEffect(.degrees(orbit && animated ? 360 : 0))
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: tiny ? 70 : compact ? 100 : 122, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [Atlas.blue, Atlas.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Atlas.blue.opacity(0.5), radius: 18)
                HomeFlagOrbit(animated: animated)
                Image(systemName: "sparkle").foregroundStyle(Atlas.gold).offset(x: 82, y: -58)
                Image(systemName: "sparkle").font(.caption).foregroundStyle(Atlas.mint).offset(x: -71, y: 55)
            }.scaleEffect(tiny ? 0.8 : 1).frame(height: tiny ? 75 : compact ? 132 : 166).accessibilityHidden(true)
                .onAppear { orbit = true }
                .animation(animated ? .linear(duration: 36).repeatForever(autoreverses: false) : nil, value: orbit && animated)
            VStack(spacing: 3) {
                Text(settings.language.text("FLAGMASTER", "我要成為國旗王", ja: "国旗チャレンジ", ko: "국기 챌린지")).font(.system(size: compact ? 31 : 36, weight: .black, design: .rounded)).tracking(1)
                    .lineLimit(1).minimumScaleFactor(0.65)
                    .shadow(color: Atlas.violet, radius: 14, y: 3)
                Text(settings.language.text("ONE WORLD. EVERY FLAG. YOUR CHALLENGE.", "看懂每面旗，挑戰全世界。", ja: "国旗を見分けて、世界に挑もう。", ko: "국기를 알아보고 세계에 도전하세요."))
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(Atlas.muted).tracking(1.5)
            }
            Button { start(.endless) } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                    Text(settings.language.text("PLAY NOW", "開始挑戰", ja: "チャレンジ開始", ko: "도전 시작")).font(.system(size: 22, weight: .black, design: .rounded))
                    Image(systemName: "chevron.right.2").font(.subheadline.bold())
                }
            }.buttonStyle(AtlasButtonStyle(filled: true, tint: Atlas.gold))
                .modifier(ActionHint(repeats: true))
                .padding(.top, 4)
        }
    }

    private func mode(title: String, detail: String, icon: String, tint: Color, compact: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 25, weight: .bold)).foregroundStyle(tint)
                    .shadow(color: tint.opacity(0.4), radius: 8).frame(width: 30)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.system(size: 16, weight: .black, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
                    Text(detail).font(.system(size: 8, weight: .bold)).foregroundStyle(tint.opacity(0.85)).lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
            }.padding(12).frame(maxWidth: .infinity, minHeight: compact ? 67 : 80)
                .modifier(GamePanel(tint: tint, radius: 20))
        }.buttonStyle(GameNavigationButtonStyle(tint: tint))
    }

    private func dock(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundStyle(tint)
                Text(title).font(.system(size: 10, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
            }.frame(maxWidth: .infinity).frame(height: 54)
        }.buttonStyle(GameNavigationButtonStyle(tint: tint))
    }
}

private struct HomeFlagOrbit: View {
    let animated: Bool
    @State private var batch = 0

    private static let batches = [
        ["JP", "BR", "CA", "ZA", "NZ", "SE"],
        ["KR", "AR", "MX", "KE", "AU", "FR"],
        ["TW", "CL", "JM", "MA", "FJ", "PT"]
    ]
    private static let positions: [CGPoint] = [
        .init(x: -108, y: -31), .init(x: 109, y: 24),
        .init(x: 113, y: -37), .init(x: -111, y: 30),
        .init(x: 40, y: -62), .init(x: -39, y: 61)
    ]

    var body: some View {
        ZStack {
            ForEach(Self.positions.indices, id: \.self) { index in
                let position = Self.positions[index]
                let code = Self.batches[batch][index]
                FlagImage(code: code)
                    .frame(width: 28, height: 19)
                    .rotationEffect(.degrees(Double(position.x) / 9))
                    .id(code)
                    .transition(.opacity)
                    .offset(x: position.x, y: position.y)
                    .phaseAnimator(animated ? [false, true] : [false]) { flag, floating in
                        flag.offset(y: floating ? (index.isMultiple(of: 2) ? -7 : 7) : 0)
                    } animation: { _ in
                        .easeInOut(duration: 1.6 + Double(index % 3) * 0.35)
                    }
            }
        }
        .task(id: animated) {
            guard animated else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(4))
                } catch {
                    return
                }
                withAnimation(.easeInOut(duration: 0.45)) {
                    batch = (batch + 1) % Self.batches.count
                }
            }
        }
    }
}

private struct HomeMotionBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.26)
                let scale = min(size.width, size.height)
                for index in 0..<3 {
                    let turn = time / (9 + Double(index) * 4) + Double(index) / 3
                    let angle = turn.truncatingRemainder(dividingBy: 1) * 360
                    let tint = [Atlas.blue, Atlas.violet, Atlas.mint][index]
                    let radius = scale * (0.31 + CGFloat(index) * 0.13)
                    var arc = Path()
                    arc.addArc(center: center, radius: radius, startAngle: .degrees(angle),
                               endAngle: .degrees(angle + 95), clockwise: false)
                    context.stroke(arc, with: .color(tint.opacity(0.18)),
                                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [9, 5]))
                }

                for index in 0..<32 {
                    let speed = 0.055 + Double(index % 5) * 0.012
                    let phase = (time * speed + Double(index) * 0.618).truncatingRemainder(dividingBy: 1)
                    let lane = Double((index * 37) % 101) / 101
                    let x = (lane + 0.035 * sin(phase * 2 * .pi + Double(index))) * size.width
                    let y = (1 - phase) * size.height
                    let brightness = sin(phase * .pi) * (index.isMultiple(of: 4) ? 0.54 : 0.27)
                    let length: CGFloat = index.isMultiple(of: 4) ? 11 : 4
                    var trail = Path()
                    trail.move(to: CGPoint(x: x, y: y))
                    trail.addLine(to: CGPoint(x: x + length * 0.3, y: y + length))
                    context.stroke(trail, with: .color(Atlas.blue.opacity(brightness)),
                                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
            }
        }
    }
}

#Preview { ZStack { AppBackground(); HomeView { _ in } }.environmentObject(AppSettings()).environmentObject(StatsStore()) }
