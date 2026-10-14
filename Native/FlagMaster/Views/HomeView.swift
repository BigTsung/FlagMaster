import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheet: Sheet?
    @State private var orbit = false
    @State private var pendingPractice: PracticePlan?
    @Environment(\.scenePhase) private var scenePhase
    @State private var now = Date()
    let start: (GameMode) -> Void
    var startPractice: (PracticePlan) -> Void = { _ in }
    enum Sheet: Identifiable { case settings, records, journeys, comparisons, flags; var id: Self { self } }
    private var en: Bool { settings.language == .english }
    private var animated: Bool { settings.animatedEffects && !reduceMotion }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                masthead
                hero
                learningRoutes
                passport
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(en ? "Choose your adventure" : "選一段新的旅程").font(.title3.bold())
                        Spacer()
                        Eyebrow(text: "03 / CHALLENGES", color: Atlas.muted)
                    }
                    ForEach(GameMode.allCases.filter { $0 != .endless && $0 != .review }) { mode in modeCard(mode) }
                }
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(Atlas.gold)
                    Text(en ? "A little curiosity. A bigger world." : "每天一點好奇心，世界就更靠近一點。")
                        .font(.caption).foregroundStyle(Atlas.muted)
                }.frame(maxWidth: .infinity).padding(.vertical, 8)
            }
            .padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { now = $0 }
        .onChange(of: scenePhase) { _, phase in if phase == .active { now = Date() } }
        .sheet(item: $sheet, onDismiss: {
            if let plan = pendingPractice { pendingPractice = nil; startPractice(plan) }
        }) { item in
            NavigationStack {
                switch item {
                case .settings: SettingsView()
                case .records: RecordsView()
                case .journeys: JourneyPickerView { pendingPractice = $0; sheet = nil }
                case .comparisons: ComparisonLibraryView { pendingPractice = $0; sheet = nil }
                case .flags: FlagLibraryView()
                }
            }.presentationDragIndicator(.visible).presentationDetents([.large])
        }
    }


    private var learningRoutes: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(en ? "Build a lasting memory" : "讓探索，變成記憶").font(.title3.bold())
            Button { start(.review) } label: {
                HStack {
                    Image(systemName: "calendar.badge.clock").font(.title2).foregroundStyle(Atlas.gold)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(en ? "Due for review: \(stats.dueCountryCodes(at: now, limit: Int.max).count)" : "到期複習：\(stats.dueCountryCodes(at: now, limit: Int.max).count) 面國旗")
                        if stats.dueCountryCodes(at: now).isEmpty, let next = stats.nextReviewDate {
                            HStack { Text(en ? "Next" : "下次"); Text(next, style: .relative) }.font(.caption).foregroundStyle(Atlas.muted)
                        } else {
                            Text(en ? "A short recall session, right on time." : "在快要忘記前，再回想一次。")
                                .font(.caption).foregroundStyle(Atlas.muted)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                }
            }.buttonStyle(AtlasButtonStyle(tint: Atlas.gold))
            Button { sheet = .journeys } label: {
                Label(en ? "Explore the region map" : "打開地圖・分區探索", systemImage: "map.fill")
            }.buttonStyle(AtlasButtonStyle(tint: Atlas.blue))
            Button { sheet = .comparisons } label: {
                Label(en ? "Compare similar flags" : "相似國旗・找出差異", systemImage: "rectangle.split.2x1")
            }.buttonStyle(AtlasButtonStyle(tint: Atlas.gold))
            Button { sheet = .flags } label: {
                Label(en ? "Browse every flag" : "瀏覽所有國家的國旗", systemImage: "square.grid.2x2.fill")
            }.buttonStyle(AtlasButtonStyle(tint: Atlas.mint))
        }
    }

    private var masthead: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "globe.asia.australia.fill").font(.title2).foregroundStyle(Atlas.mint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("FLAGMASTER").font(.system(.subheadline, design: .rounded).weight(.black)).tracking(2)
                    Text(en ? "THE WORLD IS YOUR CLASSROOM" : "你的世界探索計畫").font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.4).foregroundStyle(Atlas.muted)
                }
            }
            Spacer()
            Button { sheet = .settings } label: {
                Image(systemName: "slider.horizontal.3").frame(width: 46, height: 46)
                    .background(.white.opacity(0.06), in: Circle())
            }.accessibilityLabel(en ? "Settings" : "設定")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Circle().fill(Atlas.mint).frame(width: 6, height: 6)
                Eyebrow(text: en ? "EXPEDITION / 001" : "世界探索 / 001")
            }
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(en ? "Small flags.\nBig world." : "小小國旗，\n大大世界。")
                        .font(.system(size: 36, weight: .heavy, design: .rounded)).tracking(-1)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(en ? "Your next discovery\nis one flag away." : "從一面國旗出發，\n把世界慢慢記住。")
                        .font(.subheadline).foregroundStyle(Atlas.muted).lineSpacing(4)
                }.frame(maxWidth: .infinity, alignment: .leading)
                globe.frame(width: 125, height: 170).accessibilityHidden(true)
            }
            Button { start(.endless) } label: {
                HStack {
                    Image(systemName: "safari")
                    Text(en ? "Start exploring" : "開始探索")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
            }.buttonStyle(AtlasButtonStyle(filled: true))
            Text(en ? "UNTIMED  ·  LEARN AT YOUR OWN PACE" : "無限探索  ·  不計時  ·  跟著自己的節奏")
                .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(Atlas.muted)
                .frame(maxWidth: .infinity)
        }.modifier(AtlasCard(tint: Atlas.mint))
    }

    private var globe: some View {
        ZStack {
            Circle().fill(Atlas.mint.opacity(0.07)).frame(width: 122, height: 122)
            Circle().stroke(Atlas.mint.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 6])).frame(width: 154, height: 154)
                .rotationEffect(.degrees(orbit && animated ? 35 : 0))
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 104, weight: .ultraLight)).foregroundStyle(Atlas.mint.opacity(0.8))
                .rotationEffect(.degrees(-12))
            Text("🇯🇵").font(.system(size: 32)).rotationEffect(.degrees(12)).offset(x: 45, y: orbit && animated ? -54 : -47)
            Text("🇧🇷").font(.system(size: 32)).rotationEffect(.degrees(-14)).offset(x: -40, y: orbit && animated ? 54 : 47)
            Image(systemName: "sparkle").foregroundStyle(Atlas.gold).offset(x: -45, y: -48)
        }
        .onAppear { orbit = true }
        .animation(animated ? .easeInOut(duration: 3.5).repeatForever(autoreverses: true) : nil, value: orbit && animated)
    }

    private var passport: some View {
        Button { sheet = .records } label: {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label(en ? "Your explorer passport" : "我的探索護照", systemImage: "person.text.rectangle")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundStyle(Atlas.muted)
                }
                HStack {
                    Metric(value: "\(stats.stats.count)", label: en ? "Flags explored" : "已探索國旗")
                    Metric(value: stats.attempts == 0 ? "—" : "\(Int(stats.accuracy * 100))%", label: en ? "Accuracy" : "答題正確率", color: Atlas.gold)
                    Metric(value: "\(stats.mastered)", label: en ? "Mastered" : "熟悉國旗", color: Atlas.blue)
                }
            }.modifier(AtlasCard())
        }.buttonStyle(.plain)
    }

    private func modeCard(_ mode: GameMode) -> some View {
        Button { start(mode) } label: {
            HStack(spacing: 16) {
                Image(systemName: mode.symbol).font(.title2.bold()).foregroundStyle(mode.tint)
                    .frame(width: 50, height: 56).background(mode.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 17))
                VStack(alignment: .leading, spacing: 5) {
                    Text(mode.title(settings.language)).font(.headline)
                    Text(mode.detail(settings.language)).font(.caption).foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(mode.tint)
            }
        }.buttonStyle(AtlasButtonStyle(tint: mode.tint))
    }
}

#Preview { ZStack { AppBackground(); HomeView { _ in } }.environmentObject(AppSettings()).environmentObject(StatsStore()) }
