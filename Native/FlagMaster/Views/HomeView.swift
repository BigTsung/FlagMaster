import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var orbit = false
    let start: (GameMode) -> Void
    var open: (Sheet) -> Void = { _ in }
    enum Sheet: Identifiable { case settings, records, journeys, comparisons, flags; var id: Self { self } }
    private var en: Bool { settings.language == .english }
    private var animated: Bool { settings.animatedEffects && !reduceMotion }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 730
            VStack(spacing: compact ? 12 : 18) {
                playerBar
                hero(compact: compact, tiny: geometry.size.height < 650)
                HStack {
                    Label(en ? "CHOOSE YOUR CHALLENGE" : "選擇你的挑戰", systemImage: "bolt.shield.fill")
                        .font(.system(size: 11, weight: .black, design: .rounded)).tracking(1)
                    Spacer()
                    Text("4 MODES").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Atlas.muted)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    mode(title: en ? "Time attack" : "極限倒數", detail: en ? "60 SECOND RUSH" : "60 秒 · 挑戰極限", icon: "timer", tint: Atlas.gold, compact: compact) { start(.timedChallenge) }
                    mode(title: en ? "Speed run" : "閃電快答", detail: en ? "20 FLAGS · 5s EACH" : "20 題 · 每題 5 秒", icon: "bolt.fill", tint: Atlas.blue, compact: compact) { start(.speedRound) }
                    mode(title: en ? "Survival" : "雙心生存", detail: en ? "ONLY TWO LIVES" : "兩顆心 · 撐到最後", icon: "heart.fill", tint: Atlas.coral, compact: compact) { start(.twoLives) }
                    mode(title: en ? "World tour" : "世界闖關", detail: en ? "CONQUER 6 REGIONS" : "六大洲 · 逐區挑戰", icon: "globe.asia.australia.fill", tint: Atlas.mint, compact: compact) { open(.journeys) }
                }
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    dock(en ? "Collection" : "國旗圖鑑", icon: "square.stack.3d.up.fill", tint: Atlas.blue) { open(.flags) }
                    dock(en ? "Training" : "辨識特訓", icon: "scope", tint: Atlas.coral) { open(.comparisons) }
                    dock(en ? "Review" : "複習挑戰", icon: "arrow.clockwise", tint: Atlas.mint) { start(.review) }
                    dock(en ? "Records" : "戰績", icon: "trophy.fill", tint: Atlas.gold) { open(.records) }
                }.padding(10).modifier(GamePanel(tint: Atlas.violet, radius: 24))
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
            .frame(maxWidth: 700, maxHeight: .infinity).frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
    }

    private var playerBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "flag.checkered").font(.title3.bold()).foregroundStyle(Atlas.gold)
                .frame(width: 42, height: 42).modifier(GamePanel(tint: Atlas.gold, radius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text(en ? "FLAG CHALLENGER" : "國旗挑戰者").font(.system(size: 12, weight: .black, design: .rounded))
                Text(en ? "\(stats.stats.count) flags discovered" : "已探索 \(stats.stats.count) 面國旗")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(Atlas.muted)
            }
            Spacer()
            Button { open(.settings) } label: {
                Image(systemName: "gearshape.fill").font(.title3).frame(width: 44, height: 44)
                    .modifier(GamePanel(tint: Atlas.violet, radius: 14))
            }.buttonStyle(AtlasPressStyle(sound: nil)).accessibilityLabel(en ? "Settings" : "設定")
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
                Text("🇯🇵").font(.system(size: 31)).rotationEffect(.degrees(-14)).offset(x: -98, y: -22)
                Text("🇧🇷").font(.system(size: 31)).rotationEffect(.degrees(15)).offset(x: 96, y: 16)
                Image(systemName: "sparkle").foregroundStyle(Atlas.gold).offset(x: 82, y: -58)
                Image(systemName: "sparkle").font(.caption).foregroundStyle(Atlas.mint).offset(x: -71, y: 55)
            }.scaleEffect(tiny ? 0.8 : 1).frame(height: tiny ? 75 : compact ? 132 : 166).accessibilityHidden(true)
                .onAppear { orbit = true }
                .animation(animated ? .linear(duration: 36).repeatForever(autoreverses: false) : nil, value: orbit && animated)
            VStack(spacing: 3) {
                Text("FLAGMASTER").font(.system(size: compact ? 31 : 36, weight: .black, design: .rounded)).tracking(1)
                    .shadow(color: Atlas.violet, radius: 14, y: 3)
                Text(en ? "ONE WORLD. EVERY FLAG. YOUR CHALLENGE." : "看懂每面旗，挑戰全世界。")
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(Atlas.muted).tracking(1.5)
            }
            Button { start(.endless) } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                    Text(en ? "PLAY NOW" : "開始挑戰").font(.system(size: 22, weight: .black, design: .rounded))
                    Image(systemName: "chevron.right.2").font(.subheadline.bold())
                }
            }.buttonStyle(AtlasButtonStyle(filled: true, tint: Atlas.gold)).padding(.top, 4)
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

#Preview { ZStack { AppBackground(); HomeView { _ in } }.environmentObject(AppSettings()).environmentObject(StatsStore()) }
