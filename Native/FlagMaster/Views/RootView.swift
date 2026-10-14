import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var activeMode: GameMode?
    @State private var practice: PracticePlan?
    @State private var showingLaunch = true
    @State private var destination: HomeView.Sheet?
    @State private var sceneOpacity = 1.0
    @State private var changingScene = false

    var body: some View {
        ZStack {
            AppBackground()
            ZStack {
                if let activeMode {
                    GameView(mode: activeMode, stats: stats, settings: settings, practice: practice) {
                        changeScene { self.activeMode = nil; practice = nil; destination = nil }
                    }
                } else if let destination {
                    NavigationStack {
                        switch destination {
                        case .settings: SettingsView()
                        case .records: RecordsView()
                        case .journeys: JourneyPickerView(start: beginPractice)
                        case .comparisons: ComparisonLibraryView(start: beginPractice)
                        case .flags: FlagLibraryView()
                        }
                    }.environment(\.gameDismiss, { changeScene { self.destination = nil } })
                } else {
                    HomeView(start: { mode in
                        changeScene { practice = nil; activeMode = mode }
                    }, open: { target in changeScene { destination = target } })
                }
            }
            .opacity(sceneOpacity)
            .allowsHitTesting(!changingScene && !showingLaunch)
            .accessibilityHidden(changingScene || showingLaunch)
            if showingLaunch {
                LaunchExperienceView(reduceMotion: reduceMotion || !settings.animatedEffects)
                    .transition(.opacity).zIndex(20)
            }
        }
        .tint(Atlas.mint)
        .onAppear {
            AudioManager.shared.configure(music: settings.musicVolume, sound: settings.soundVolume)
            AudioManager.shared.playMusic(.home)
            Task { @MainActor in
                if reduceMotion || !settings.animatedEffects {
                    try? await Task.sleep(for: .milliseconds(450))
                } else {
                    try? await Task.sleep(for: .milliseconds(2100))
                }
                withAnimation(.easeOut(duration: 0.35)) { showingLaunch = false }
            }
        }
        .onChange(of: activeMode) { _, mode in
            AudioManager.shared.setDucked(false)
            AudioManager.shared.playMusic(mode == nil ? .home : .game)
        }
        .onChange(of: settings.musicVolume) { _, level in AudioManager.shared.updateMusicVolume(level) }
        .onChange(of: settings.soundVolume) { _, level in AudioManager.shared.updateSoundVolume(level) }
        .onChange(of: scenePhase) { _, phase in AudioManager.shared.setAppActive(phase == .active) }
        #if DEBUG
        .task { await previewTransitions() }
        #endif
    }

    private func beginPractice(_ plan: PracticePlan) {
        changeScene { destination = nil; practice = plan; activeMode = .endless }
    }

    private func changeScene(_ update: @escaping () -> Void) {
        guard !changingScene else { return }
        guard settings.animatedEffects else { update(); return }
        changingScene = true
        // Swap only after the outgoing scene has faded, so timers start with
        // the incoming scene instead of running underneath another screen.
        let duration = reduceMotion ? 0.10 : 0.18
        withAnimation(.easeIn(duration: duration), completionCriteria: .removed) {
            sceneOpacity = 0
        } completion: {
            update()
            withAnimation(.easeOut(duration: duration), completionCriteria: .removed) {
                sceneOpacity = 1
            } completion: {
                changingScene = false
            }
        }
    }

    #if DEBUG
    private func previewTransitions() async {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--preview-screen"), args.contains("--preview-transitions") else { return }
        func report(_ message: String) { FileHandle.standardError.write(Data((message + "\n").utf8)) }
        report("START: scene transition validation")
        do {
            try await Task.sleep(for: .seconds(3))
            for target in [HomeView.Sheet.flags, .comparisons, .records, .settings, .journeys] {
                changeScene { destination = target }
                try await Task.sleep(for: .seconds(1))
                assert(destination == target && !changingScene && sceneOpacity == 1)
                changeScene { destination = nil }
                try await Task.sleep(for: .seconds(1))
                assert(destination == nil && !changingScene && sceneOpacity == 1)
                report("PASS: panel \(target)")
            }
            for mode in [GameMode.endless, .timedChallenge, .speedRound, .twoLives, .review] {
                changeScene { activeMode = mode }
                try await Task.sleep(for: .seconds(1))
                assert(activeMode == mode && !changingScene && sceneOpacity == 1)
                changeScene { activeMode = nil }
                try await Task.sleep(for: .seconds(1))
                assert(activeMode == nil && !changingScene && sceneOpacity == 1)
                report("PASS: mode \(mode)")
            }
            changeScene { destination = .journeys }
            try await Task.sleep(for: .seconds(1))
            beginPractice(.region(.asia))
            try await Task.sleep(for: .seconds(1))
            assert(destination == nil && activeMode == .endless && practice != nil && !changingScene)
            changeScene { activeMode = nil; practice = nil }
            try await Task.sleep(for: .seconds(1))
            assert(sceneOpacity == 1 && !changingScene)
            report("PASS: all panel, game, return and region-start fades completed")
        } catch { report("CANCELLED: scene transition validation") }
    }
    #endif
}

private struct LaunchExperienceView: View {
    let reduceMotion: Bool
    @State private var revealed = false
    @State private var orbit = false

    var body: some View {
        ZStack {
            AppBackground()
            RadialGradient(colors: [Atlas.violet.opacity(revealed ? 0.45 : 0.04), .clear], center: .center, startRadius: 0, endRadius: 430)
                .ignoresSafeArea()
            ForEach(0..<16, id: \.self) { index in
                let angle = Double(index) * .pi * 2 / 16
                Circle().fill(index.isMultiple(of: 3) ? Atlas.gold : Atlas.mint)
                    .frame(width: index.isMultiple(of: 3) ? 5 : 3)
                    .offset(x: cos(angle) * (orbit ? 175 : 78), y: sin(angle) * (orbit ? 260 : 105))
                    .opacity(orbit ? 0.08 : 0.65)
            }
            ZStack {
                Circle().stroke(Atlas.mint.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 8])).frame(width: 210, height: 210)
                    .rotationEffect(.degrees(orbit ? 120 : 0))
                Circle().fill(Atlas.panel).frame(width: 142, height: 142)
                    .overlay(Circle().stroke(Atlas.mint.opacity(0.35), lineWidth: 1))
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 96, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [Atlas.blue, Atlas.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Atlas.violet.opacity(0.7), radius: 24)
                    .symbolEffect(.pulse, options: .repeating.speed(0.55), value: revealed && !reduceMotion)
                Text("🇹🇼").font(.system(size: 31)).offset(x: orbit ? 92 : 58, y: orbit ? -58 : -32).rotationEffect(.degrees(8))
                Text("🇧🇷").font(.system(size: 31)).offset(x: orbit ? -88 : -55, y: orbit ? 68 : 36).rotationEffect(.degrees(-12))
                Image(systemName: "sparkles").font(.title).foregroundStyle(Atlas.gold).offset(x: -83, y: -78)
            }
            .scaleEffect(revealed ? 1 : 0.58).opacity(revealed ? 1 : 0)
            VStack(spacing: 8) {
                Spacer()
                Text("FLAGMASTER").font(.system(size: 29, weight: .black, design: .rounded)).tracking(5)
                Text("THE WORLD IS YOUR ARENA").font(.system(size: 10, weight: .black, design: .rounded)).tracking(2).foregroundStyle(Atlas.gold)
                HStack(spacing: 5) {
                    ForEach(0..<7) { index in
                        Capsule().fill(Atlas.gold.opacity(revealed ? 1 : 0.15)).frame(width: 19, height: 5)
                            .animation(reduceMotion ? nil : .easeIn(duration: 0.25).delay(Double(index) * 0.18), value: revealed)
                    }
                }.padding(.top, 14)
            }.padding(.bottom, 86).offset(y: revealed ? 0 : 20).opacity(revealed ? 1 : 0)
        }
        .foregroundStyle(.white).allowsHitTesting(true).accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { revealed = true; return }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) { revealed = true }
            withAnimation(.easeOut(duration: 1.8)) { orbit = true }
        }
    }
}

enum Atlas {
    static let ink = Color(red: 0.055, green: 0.035, blue: 0.16)
    static let panel = Color(red: 0.15, green: 0.105, blue: 0.30)
    static let mint = Color(red: 0.40, green: 1, blue: 0.79)
    static let gold = Color(red: 1, green: 0.81, blue: 0.24)
    static let coral = Color(red: 1, green: 0.36, blue: 0.55)
    static let blue = Color(red: 0.37, green: 0.80, blue: 1)
    static let violet = Color(red: 0.64, green: 0.43, blue: 1)
    static let muted = Color(red: 0.72, green: 0.69, blue: 0.86)
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            Atlas.ink
            RadialGradient(colors: [Atlas.violet.opacity(0.34), .clear], center: .top, startRadius: 0, endRadius: 600)
            RadialGradient(colors: [Atlas.blue.opacity(0.13), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 380)
            Canvas { context, size in
                for index in 0..<65 {
                    let x = CGFloat((index * 127 + 19) % 997) / 997 * size.width
                    let y = CGFloat((index * 211 + 73) % 991) / 991 * size.height
                    let radius: CGFloat = index.isMultiple(of: 7) ? 2 : 1
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)), with: .color(.white.opacity(index.isMultiple(of: 7) ? 0.5 : 0.18)))
                }
                var horizon = Path()
                for index in -5...5 {
                    horizon.move(to: CGPoint(x: size.width / 2, y: size.height * 0.67))
                    horizon.addLine(to: CGPoint(x: size.width / 2 + CGFloat(index) * 130, y: size.height))
                }
                for fraction in [0.76, 0.82, 0.90, 0.99] {
                    horizon.move(to: CGPoint(x: 0, y: size.height * fraction))
                    horizon.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
                }
                context.stroke(horizon, with: .color(Atlas.violet.opacity(0.13)), lineWidth: 1)
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}

struct GamePanel: ViewModifier {
    var tint: Color = Atlas.violet
    var radius: CGFloat = 24
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radius).fill(Color.black.opacity(0.35)).offset(y: 5))
            .background(LinearGradient(colors: [Atlas.panel, Atlas.ink.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(LinearGradient(colors: [tint.opacity(0.65), tint.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
    }
}

private struct GameDismissKey: EnvironmentKey {
    static let defaultValue: (@MainActor @Sendable () -> Void)? = nil
}

extension EnvironmentValues {
    var gameDismiss: (@MainActor @Sendable () -> Void)? {
        get { self[GameDismissKey.self] }
        set { self[GameDismissKey.self] = newValue }
    }
}

struct GameScreen: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.gameDismiss) private var gameDismiss
    let title: String
    let symbol: String
    var tint: Color = Atlas.violet
    func body(content: Content) -> some View {
        content.toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: symbol).font(.title3.bold()).foregroundStyle(tint)
                        .frame(width: 42, height: 42).modifier(GamePanel(tint: tint, radius: 13))
                    Text(title).font(.system(.headline, design: .rounded).weight(.heavy))
                    Spacer()
                    Button { if let gameDismiss { gameDismiss() } else { dismiss() } } label: {
                        Image(systemName: "xmark").font(.headline.bold()).frame(width: 44, height: 44)
                            .modifier(GamePanel(tint: Atlas.muted, radius: 14))
                    }.buttonStyle(AtlasPressStyle(sound: nil))
                        .accessibilityLabel(Text("Close", comment: "Close game panel"))
                }.foregroundStyle(.white).padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Atlas.ink.opacity(0.65))
            }
    }
}

struct AtlasCard: ViewModifier {
    var tint: Color = .white
    func body(content: Content) -> some View {
        content.padding(18).modifier(GamePanel(tint: tint))
    }
}

struct AtlasButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    var filled = false
    var tint: Color = Atlas.mint
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(filled ? Atlas.ink : .white)
            .padding(.horizontal, 18).padding(.vertical, 17)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 18).fill(filled ? tint.opacity(0.45) : Color.black.opacity(0.45)).offset(y: configuration.isPressed ? 1 : 5)
                RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: filled ? [tint, tint.opacity(0.82)] : [Atlas.panel.opacity(0.9), Atlas.panel], startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(filled ? 0.4 : 0.14), lineWidth: 1.5)
            }
            .shadow(color: filled ? tint.opacity(0.20) : .clear, radius: 16, y: 5)
            .offset(y: configuration.isPressed ? 3 : 0)
            .scaleEffect(configuration.isPressed && !reduceMotion && settings.animatedEffects ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion || !settings.animatedEffects ? nil : .spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in if pressed { AudioManager.shared.play(.tap) } }
    }
}

struct Eyebrow: View {
    let text: String
    var color: Color = Atlas.mint
    var body: some View {
        Text(text).font(.system(size: 10, weight: .black, design: .rounded)).tracking(1.8).foregroundStyle(color)
    }
}

struct Metric: View {
    let value: String
    let label: String
    var color: Color = Atlas.mint
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text(value).font(.system(size: 26, weight: .black, design: .rounded)).monospacedDigit().foregroundStyle(color).contentTransition(.numericText())
            Text(label).font(.caption).foregroundStyle(Atlas.muted)
        }.frame(maxWidth: .infinity)
    }
}

extension GameMode {
    var tint: Color {
        switch self {
        case .endless: Atlas.mint
        case .timedChallenge: Atlas.gold
        case .speedRound: Atlas.blue
        case .twoLives: Atlas.coral
        case .review: Color(red: 0.77, green: 0.69, blue: 1)
        }
    }
    func detail(_ language: AppLanguage) -> String {
        let en = language == .english
        switch self {
        case .endless: return en ? "No timer. A world to discover." : "沒有倒數，按自己的節奏探索"
        case .timedChallenge: return en ? "60 seconds. How far can you go?" : "60 秒倒數，挑戰你的辨識力"
        case .speedRound: return en ? "20 flags · 5 seconds each" : "20 道題目，每題 5 秒快問快答"
        case .twoLives: return en ? "Two hearts. Make them count." : "兩顆愛心，每一次選擇都重要"
        case .review: return en ? "Revisit flags when they are due." : "在適合的時間回想，讓記憶更深刻"
        }
    }
}

#Preview { RootView().environmentObject(AppSettings()).environmentObject(StatsStore()) }


struct AtlasPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    var sound: SoundEffect? = .tap
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion && settings.animatedEffects ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion || !settings.animatedEffects ? nil : .spring(response: 0.22), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed, let sound { AudioManager.shared.play(sound) }
            }
    }
}

struct GameNavigationButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: 15))
            .background(tint.opacity(configuration.isPressed ? 0.23 : 0), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(tint.opacity(configuration.isPressed ? 0.9 : 0), lineWidth: 2))
            .shadow(color: tint.opacity(configuration.isPressed ? 0.55 : 0), radius: 12)
            .scaleEffect(configuration.isPressed && !reduceMotion && settings.animatedEffects ? 0.90 : 1)
            .animation(settings.animatedEffects ? .easeOut(duration: 0.10) : nil, value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in
                pressed && settings.hapticsEnabled
            }
    }
}

struct DiscoveryBurst: View {
    @State private var expanded = false
    var body: some View {
        ZStack {
            ForEach(0..<12) { index in
                let angle = Double(index) * .pi / 6
                Image(systemName: index.isMultiple(of: 3) ? "sparkle" : "circle.fill")
                    .font(.system(size: index.isMultiple(of: 3) ? 15 : 5))
                    .foregroundStyle(index.isMultiple(of: 2) ? Atlas.mint : Atlas.gold)
                    .offset(x: cos(angle) * (expanded ? 145 : 35), y: sin(angle) * (expanded ? 88 : 20))
                    .opacity(expanded ? 0 : 1)
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
        .onAppear { withAnimation(.easeOut(duration: 0.85)) { expanded = true } }
    }
}
