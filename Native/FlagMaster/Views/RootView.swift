import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var activeMode: GameMode?
    @State private var practice: PracticePlan?

    var body: some View {
        ZStack {
            AppBackground()
            if let activeMode {
                GameView(mode: activeMode, stats: stats, settings: settings, practice: practice) { self.activeMode = nil; practice = nil }
                    .transition(.opacity)
            } else {
                HomeView(start: { practice = nil; activeMode = $0 }, startPractice: { practice = $0; activeMode = .endless }).transition(.opacity)
            }
        }
        .tint(Atlas.mint)
        .animation(reduceMotion || !settings.animatedEffects ? nil : .easeInOut(duration: 0.3), value: activeMode)
        .onAppear {
            AudioManager.shared.configure(music: settings.musicVolume, sound: settings.soundVolume)
            AudioManager.shared.playMusic(.home)
        }
        .onChange(of: activeMode) { _, mode in
            AudioManager.shared.setDucked(false)
            AudioManager.shared.playMusic(mode == nil ? .home : .game)
        }
        .onChange(of: settings.musicVolume) { _, level in AudioManager.shared.updateMusicVolume(level) }
        .onChange(of: settings.soundVolume) { _, level in AudioManager.shared.updateSoundVolume(level) }
        .onChange(of: scenePhase) { _, phase in AudioManager.shared.setAppActive(phase == .active) }
    }
}

enum Atlas {
    static let ink = Color(red: 0.035, green: 0.075, blue: 0.10)
    static let panel = Color(red: 0.075, green: 0.13, blue: 0.16)
    static let mint = Color(red: 0.66, green: 0.94, blue: 0.70)
    static let gold = Color(red: 1, green: 0.79, blue: 0.40)
    static let coral = Color(red: 1, green: 0.52, blue: 0.43)
    static let blue = Color(red: 0.49, green: 0.76, blue: 0.94)
    static let muted = Color(red: 0.64, green: 0.74, blue: 0.76)
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            Atlas.ink
            RadialGradient(colors: [Atlas.mint.opacity(0.09), .clear], center: .topTrailing, startRadius: 0, endRadius: 650)
            Canvas { context, size in
                var grid = Path()
                for x in stride(from: 0.0, through: size.width, by: 44) {
                    grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0.0, through: size.height, by: 44) {
                    grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(.white.opacity(0.025)), lineWidth: 0.5)
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}

struct AtlasCard: ViewModifier {
    var tint: Color = .white
    func body(content: Content) -> some View {
        content.padding(20)
            .background(Atlas.panel, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(tint.opacity(0.15), lineWidth: 1))
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
            .background(filled ? tint : Atlas.panel, in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(tint.opacity(filled ? 0 : 0.22)))
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
        Text(text).font(.system(.caption2, design: .monospaced).weight(.bold)).tracking(2).foregroundStyle(color)
    }
}

struct Metric: View {
    let value: String
    let label: String
    var color: Color = Atlas.mint
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.system(.title2, design: .rounded).weight(.heavy)).monospacedDigit().foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(Atlas.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
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
