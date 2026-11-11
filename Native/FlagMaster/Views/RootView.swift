import SwiftUI
import UIKit

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

    private var menuMusic: AudioTrack? {
        guard activeMode == nil else { return nil }
        switch destination {
        case .journeys: return .region
        case .comparisons: return .comparison
        default: return .home
        }
    }

    var body: some View {
        ZStack {
            AppBackground(style: activeMode == nil && destination == nil ? .home : .calm)
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
                    }, open: { target in changeScene { destination = target } },
                    isVisible: !showingLaunch && !changingScene)
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
            AudioManager.shared.setAppActive(scenePhase == .active)
            if let menuMusic { AudioManager.shared.playMusic(menuMusic) }
            Task { @MainActor in
                if reduceMotion || !settings.animatedEffects {
                    try? await Task.sleep(for: .milliseconds(450))
                } else {
                    try? await Task.sleep(for: .milliseconds(1800))
                }
                withAnimation(.easeOut(duration: 0.35)) { showingLaunch = false }
            }
        }
        .onChange(of: menuMusic) { _, track in
            if let track { AudioManager.shared.playMusic(track) }
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
        withAnimation(.easeIn(duration: duration)) { sceneOpacity = 0 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            update()
            withAnimation(.easeOut(duration: duration)) { sceneOpacity = 1 }
            try? await Task.sleep(for: .seconds(duration))
            changingScene = false
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
                assert(destination == target && !changingScene && sceneOpacity == 1, "Panel transition did not finish: \(target)")
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
    @EnvironmentObject private var settings: AppSettings
    let reduceMotion: Bool
    @State private var revealed = false
    @State private var burst = false

    private static let orbitFlags: [(String, CGFloat, CGFloat, Double)] = [
        ("TW", 96, -62, 10), ("BR", -92, 70, -12), ("JP", -100, -48, -6), ("FR", 104, 58, 8)
    ]

    var body: some View {
        ZStack {
            AppBackground(style: .home)
            RadialGradient(colors: [Atlas.cardMint.opacity(revealed ? 0.45 : 0.05), Atlas.yellow.opacity(revealed ? 0.16 : 0), .clear],
                           center: .center, startRadius: 0, endRadius: 360)
                .ignoresSafeArea()
            ForEach(0..<18, id: \.self) { index in
                let angle = Double(index) * .pi * 2 / 18
                let palette = [Atlas.gold, Atlas.mint, Atlas.blue, Atlas.coral]
                Circle().fill(palette[index % 4])
                    .frame(width: index.isMultiple(of: 3) ? 6 : 3.5)
                    .shadow(color: palette[index % 4], radius: 4)
                    .offset(x: cos(angle) * (burst ? 185 : 70), y: sin(angle) * (burst ? 250 : 92))
                    .opacity(burst ? 0 : 0.85)
            }
            ZStack {
                Circle().stroke(Atlas.mint.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 8]))
                    .frame(width: 222, height: 222).rotationEffect(.degrees(burst ? 140 : 0))
                Circle().trim(from: 0, to: 0.32)
                    .stroke(AngularGradient(colors: [.clear, Atlas.yellow], center: .center), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 186, height: 186).rotationEffect(.degrees(burst ? 300 : -40))
                Circle().fill(Atlas.panel).frame(width: 146, height: 146)
                    .overlay(Circle().stroke(Atlas.cardMint.opacity(0.8), lineWidth: 1.5))
                    .shadow(color: Atlas.cardMint.opacity(0.55), radius: 28)
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 92, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [Atlas.mint, Atlas.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Atlas.blue.opacity(0.45), radius: 16)
                ForEach(Self.orbitFlags.indices, id: \.self) { index in
                    let item = Self.orbitFlags[index]
                    FlagImage(code: item.0).frame(width: 40, height: 27)
                        .padding(4).background(Atlas.panel, in: RoundedRectangle(cornerRadius: 8))
                        .shadow(color: Atlas.cardMint.opacity(0.5), radius: 8)
                        .rotationEffect(.degrees(item.3))
                        .offset(x: burst ? item.1 : item.1 * 0.55, y: burst ? item.2 : item.2 * 0.55)
                }
                Image(systemName: "sparkle").font(.system(size: 22, weight: .bold)).foregroundStyle(Atlas.gold)
                    .shadow(color: Atlas.yellow, radius: 8).offset(x: -78, y: 92)
                Image(systemName: "sparkle").font(.system(size: 14, weight: .bold)).foregroundStyle(Atlas.mint)
                    .offset(x: 82, y: -100)
            }
            .scaleEffect(revealed ? 1 : 0.6).opacity(revealed ? 1 : 0)
            VStack(spacing: 8) {
                Spacer()
                Text(settings.language.appName)
                    .font(.system(size: 30, weight: .black, design: .rounded)).tracking(3)
                    .lineLimit(1).minimumScaleFactor(0.75)
                    .shadow(color: Atlas.cardMint.opacity(0.6), radius: 12)
                Text(settings.language.text("LITTLE FLAGS. BIG WORLD.", "小小國旗，大大世界", ja: "小さな国旗、大きな世界", ko: "작은 국기, 커다란 세상"))
                    .font(.system(size: 12, weight: .bold, design: .rounded)).tracking(2).foregroundStyle(Atlas.gold)
                HStack(spacing: 5) {
                    ForEach(0..<7) { index in
                        Capsule().fill(Atlas.yellow.opacity(revealed ? 1 : 0.2)).frame(width: 19, height: 5)
                            .shadow(color: Atlas.yellow.opacity(revealed ? 0.8 : 0), radius: 4)
                            .animation(reduceMotion ? nil : .easeIn(duration: 0.2).delay(Double(index) * 0.14), value: revealed)
                    }
                }.padding(.top, 14)
            }.padding(.bottom, 86).offset(y: revealed ? 0 : 20).opacity(revealed ? 1 : 0)
        }
        .foregroundStyle(Atlas.text).allowsHitTesting(true).accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { revealed = true; burst = true; return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { revealed = true }
            withAnimation(.easeOut(duration: 1.6)) { burst = true }
        }
    }
}

enum Atlas {
    private static func rgb(_ value: UInt32) -> Color {
        Color(red: Double((value >> 16) & 255) / 255,
              green: Double((value >> 8) & 255) / 255,
              blue: Double(value & 255) / 255)
    }
    static let ink = rgb(0x142623)
    static let panel = rgb(0x243833)
    static let text = rgb(0xF6F7F0)
    static let muted = rgb(0xBCC3BC)
    static let line = rgb(0x456058)
    static let mint = rgb(0xBCEACD)
    static let blue = rgb(0xB8DFEB)
    static let coral = rgb(0xF6B499)
    static let gold = rgb(0xFFE33E)
    static let accent = rgb(0xCCD5CA)
    static let yellow = Color(red: 1, green: 0.89, blue: 0.23)
    static let cardMint = Color(red: 0.76, green: 0.93, blue: 0.82)
    static let cardBlue = Color(red: 0.76, green: 0.89, blue: 0.95)
    static let onAccent = Color(red: 0.15, green: 0.17, blue: 0.16)
    static let paper = ink
    static let printInk = text
    static let printRed = gold
}

/// Decorative explorer map. The calmer variant keeps the route behind quiz content.
struct AppBackground: View {
    enum Style { case calm, home }
    var style: Style = .calm
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var animated: Bool { settings.animatedEffects && !reduceMotion && scenePhase == .active }

    private struct Stamp {
        let symbol: String
        let color: Color
        let position: CGPoint
        let angle: Double
    }

    private static let stamps = [
        Stamp(symbol: "airplane", color: Atlas.blue, position: CGPoint(x: 0.89, y: 0.36), angle: 15),
        Stamp(symbol: "location.north.line", color: Atlas.gold, position: CGPoint(x: 0.08, y: 0.39), angle: -16),
        Stamp(symbol: "binoculars.fill", color: Atlas.mint, position: CGPoint(x: 0.92, y: 0.65), angle: 12),
        Stamp(symbol: "mountain.2.fill", color: Atlas.coral, position: CGPoint(x: 0.09, y: 0.68), angle: -12),
        Stamp(symbol: "sailboat.fill", color: Atlas.blue, position: CGPoint(x: 0.89, y: 0.79), angle: 12),
        Stamp(symbol: "flag.fill", color: Atlas.gold, position: CGPoint(x: 0.12, y: 0.88), angle: -18)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated)) { timeline in
            let time = animated ? timeline.date.timeIntervalSinceReferenceDate : 0
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    LinearGradient(colors: [Color(red: 0.09, green: 0.23, blue: 0.21), Atlas.ink,
                                            Color(red: 0.07, green: 0.16, blue: 0.22)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    RadialGradient(colors: [Atlas.mint.opacity(style == .home ? 0.16 : 0.07), .clear],
                                   center: .trailing, startRadius: 0, endRadius: max(size.width, size.height) * 0.64)
                    Canvas { context, size in drawMap(in: context, size: size) }
                    ForEach(style == .home ? [0, 3, 5] : Array(Self.stamps.indices), id: \.self) { index in
                        let stamp = Self.stamps[index]
                        let bob = sin(time * 1.2 + Double(index)) * 5
                        let side: CGFloat = style == .home ? 39 : 33
                        Image(systemName: stamp.symbol)
                            .font(.system(size: side * 0.48, weight: .semibold))
                            .foregroundStyle(stamp.color)
                            .frame(width: side, height: side)
                            .background(stamp.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 11))
                            .overlay(RoundedRectangle(cornerRadius: 11)
                                .strokeBorder(stamp.color.opacity(0.52), style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
                            .rotationEffect(.degrees(stamp.angle))
                            .opacity(style == .home ? 0.85 : 0.38)
                            .position(x: stamp.position.x * size.width, y: stamp.position.y * size.height + bob)
                    }
                }
            }
        }
        .ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }

    private func drawMap(in context: GraphicsContext, size: CGSize) {
        var dots = Path()
        for x in stride(from: CGFloat(12), to: size.width, by: 22) {
            for y in stride(from: CGFloat(12), to: size.height, by: 22) {
                dots.addEllipse(in: CGRect(x: x, y: y, width: 1.6, height: 1.6))
            }
        }
        context.fill(dots, with: .color(Atlas.mint.opacity(0.17)))

        let reach = min(size.width, size.height)
        var contours = Path()
        for offset in stride(from: reach * 0.18, through: reach * 0.48, by: 15) {
            contours.addEllipse(in: CGRect(x: -offset, y: -offset * 0.60, width: offset * 2.8, height: offset * 1.9))
            contours.addEllipse(in: CGRect(x: size.width - offset * 1.6, y: size.height - offset,
                                           width: offset * 2.8, height: offset * 1.8))
        }
        context.stroke(contours, with: .color(Atlas.blue.opacity(0.14)), lineWidth: 1)

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * size.width, y: y * size.height)
        }

        var route = Path()
        route.move(to: point(-0.06, 0.40))
        route.addCurve(to: point(0.88, 0.35), control1: point(0.35, 0.49), control2: point(0.57, 0.16))
        route.addCurve(to: point(0.12, 0.71), control1: point(1.18, 0.54), control2: point(0.15, 0.55))
        route.addCurve(to: point(1.06, 0.87), control1: point(0.07, 0.87), control2: point(0.77, 0.74))
        context.stroke(route, with: .linearGradient(
            Gradient(colors: [Atlas.gold, Atlas.mint, Atlas.blue].map { $0.opacity(style == .home ? 0.58 : 0.24) }),
            startPoint: .zero, endPoint: point(0.85, 0.85)),
            style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [4, 8]))
    }
}

struct GamePanel: ViewModifier {
    var tint: Color = Atlas.accent
    var radius: CGFloat = 24
    func body(content: Content) -> some View {
        content
            .background(Atlas.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(
                LinearGradient(colors: [tint.opacity(0.55), Atlas.line.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1.2))
            .shadow(color: tint.opacity(0.14), radius: 14, y: 6)
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
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.gameDismiss) private var gameDismiss
    let title: String
    let symbol: String
    var tint: Color = Atlas.accent
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
                        .accessibilityLabel(settings.language.text("Close", "關閉", ja: "閉じる", ko: "닫기"))
                }.foregroundStyle(Atlas.text).padding(.horizontal, 20).padding(.vertical, 10)
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
            .foregroundStyle(filled ? Atlas.onAccent : Atlas.text)
            .padding(.horizontal, 18).padding(.vertical, 17)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20).fill(filled
                    ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.96, blue: 0.5), Atlas.yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Atlas.panel.opacity(0.92)))
                RoundedRectangle(cornerRadius: 20).stroke(filled ? Color.white.opacity(0.5) : tint.opacity(0.45), lineWidth: 1.2)
            }
            .shadow(color: (filled ? Atlas.yellow : tint).opacity(filled ? 0.38 : 0.14), radius: filled ? 16 : 10, y: 6)
            .offset(y: configuration.isPressed ? 3 : 0)
            .scaleEffect(configuration.isPressed && !reduceMotion && settings.animatedEffects ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion || !settings.animatedEffects ? nil : .spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in if pressed { AudioManager.shared.play(.tap) } }
    }
}

struct ActionHint: ViewModifier {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.scenePhase) private var scenePhase
    @State private var glowing = false
    @State private var didHint = false
    var repeats = false

    private var active: Bool {
        settings.animatedEffects && !reduceMotion && isEnabled && scenePhase == .active
    }

    func body(content: Content) -> some View {
        content.overlay {
            Group {
                if repeats {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.20), .white.opacity(0.75), .white.opacity(0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .blendMode(.screen)
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.white, lineWidth: 2)
                        .shadow(color: Atlas.gold, radius: 8)
                }
            }
            .opacity(active && glowing ? 0.85 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .task(id: active) {
            glowing = false
            guard active, repeats || !didHint else { return }
            let clock = ContinuousClock()
            var next = clock.now + (repeats ? .seconds(5) : .milliseconds(850))
            do {
                repeat {
                    try await clock.sleep(until: next)
                    didHint = true
                    withAnimation(.easeOut(duration: 0.15)) { glowing = true }
                    try await clock.sleep(for: .milliseconds(150))
                    withAnimation(.easeOut(duration: 0.45)) { glowing = false }
                    next = clock.now + .milliseconds(4850)
                } while repeats
            } catch {
                // A new task resets the glow when hints are disabled or resumed.
            }
        }
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
        case .review: Atlas.blue
        }
    }
    func detail(_ language: AppLanguage) -> String {
        switch self {
        case .endless: return language.text("No timer. A world to discover.", "沒有倒數，按自己的節奏探索", ja: "時間制限なし。自分のペースで探検しよう。", ko: "시간 제한 없이 내 속도로 탐험해 보세요.")
        case .timedChallenge: return language.text("60 seconds. How far can you go?", "60 秒倒數，挑戰你的辨識力", ja: "60 秒で何問答えられるかな？", ko: "60초 동안 몇 문제를 맞힐 수 있을까요?")
        case .speedRound: return language.text("20 flags · 5 seconds each", "20 道題目，每題 5 秒快問快答", ja: "20 問、各 5 秒で回答", ko: "20문제, 문제당 5초")
        case .twoLives: return language.text("Two hearts. Make them count.", "兩顆愛心，每一次選擇都重要", ja: "ライフは 2 つ。慎重に選ぼう。", ko: "기회는 두 번. 신중히 선택하세요.")
        case .review: return language.text("Revisit flags when they are due.", "在適合的時間回想，讓記憶更深刻", ja: "復習の時期が来た国旗を思い出そう。", ko: "복습할 때가 된 국기를 떠올려 보세요.")
        }
    }
}

/// Canvas previews bypass FlagMasterApp, so they need their own observed app environment.
struct AppPreview<Content: View>: View {
    @StateObject private var settings = AppSettings()
    @StateObject private var stats = StatsStore()
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .environmentObject(settings)
            .environmentObject(stats)
            .preferredColorScheme(.dark)
            .environment(\.locale, settings.language.locale)
    }
}

#Preview { AppPreview { RootView() } }


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
