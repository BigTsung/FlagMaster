import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false
    @State private var section: Section = .general
    private var en: Bool { settings.language == .english }

    private enum Section: String, CaseIterable, Identifiable {
        case general, audio, learning, data
        var id: Self { self }
    }

    var body: some View {
        ZStack {
            AppBackground()
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 16) {
                    Eyebrow(text: "GAME OPTIONS", color: Atlas.violet)
                    Text(en ? "Make it your game" : "打造你的遊戲體驗").font(.system(.title2, design: .rounded).weight(.black))
                    sectionPicker
                    Group {
                        switch section {
                        case .general: generalPanel
                        case .audio: audioPanel
                        case .learning: learningPanel
                        case .data: dataPanel
                        }
                    }.frame(maxHeight: .infinity, alignment: .top)
                    Text("FLAGMASTER · \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.system(.caption2, design: .monospaced)).tracking(2).foregroundStyle(Atlas.muted).frame(maxWidth: .infinity)
                }.padding(20).frame(maxWidth: 700, maxHeight: .infinity).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(.white)
        .navigationTitle(en ? "Settings" : "旅程設定").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() }.tint(Atlas.mint) } }
        .toolbarBackground(Atlas.ink, for: .navigationBar)
        .modifier(GameScreen(title: en ? "OPTIONS" : "遊戲設定", symbol: "gearshape.fill"))
        .confirmationDialog(en ? "Clear all answer history?" : "要清除所有答題紀錄嗎？", isPresented: $confirmClear, titleVisibility: .visible) {
            Button(en ? "Clear history" : "清除紀錄", role: .destructive) { stats.clear() }
            Button(en ? "Cancel" : "取消", role: .cancel) {}
        } message: { Text(en ? "Your passport and review history will be reset." : "探索護照與錯題紀錄將歸零。") }
    }

    private var sectionPicker: some View {
        HStack(spacing: 8) {
            sectionButton(.general, title: en ? "Game" : "遊戲", icon: "gamecontroller.fill")
            sectionButton(.audio, title: en ? "Audio" : "音效", icon: "speaker.wave.2.fill")
            sectionButton(.learning, title: en ? "Rules" : "規則", icon: "book.closed.fill")
            sectionButton(.data, title: en ? "Save" : "存檔", icon: "externaldrive.fill")
        }
    }

    private func sectionButton(_ value: Section, title: String, icon: String) -> some View {
        Button { section = value } label: {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.system(size: 11, weight: .bold))
            }.foregroundStyle(section == value ? Atlas.gold : Atlas.muted)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .modifier(GamePanel(tint: section == value ? Atlas.gold : Atlas.violet, radius: 16))
        }.buttonStyle(GameNavigationButtonStyle(tint: Atlas.gold)).accessibilityAddTraits(section == value ? .isSelected : [])
    }

    private var generalPanel: some View {
        panel(en ? "Interface" : "介面", symbol: "character.bubble", tint: Atlas.mint) {
            Text(en ? "Language" : "介面語言").font(.headline)
            Picker(en ? "Language" : "介面語言", selection: $settings.language) {
                Text("繁體中文").tag(AppLanguage.traditionalChinese); Text("English").tag(AppLanguage.english)
            }.pickerStyle(.segmented)
            Divider().overlay(.white.opacity(0.08))
            Toggle(en ? "Animated effects" : "動態視覺效果", isOn: $settings.animatedEffects).tint(Atlas.mint)
            Toggle(en ? "Haptic feedback" : "答題觸覺回饋", isOn: $settings.hapticsEnabled).tint(Atlas.mint)
        }
    }

    private var audioPanel: some View {
        panel(en ? "Atmosphere & feedback" : "氣氛與互動", symbol: "waveform", tint: Atlas.gold) {
            Text(en ? "Background music" : "背景音樂").font(.headline)
            volumePicker(selection: $settings.musicVolume, label: en ? "Music volume" : "背景音樂音量")
            Text(en ? "Exploration ambience on the home screen; a stronger pulse during challenges." : "首頁使用探索氛圍；進入挑戰後切換成更有推進感的節奏。")
                .font(.caption).foregroundStyle(Atlas.muted)
            Divider().overlay(.white.opacity(0.08))
            Text(en ? "Sound effects" : "互動音效").font(.headline)
            volumePicker(selection: $settings.soundVolume, label: en ? "Sound volume" : "互動音效音量")
            Text(en ? "Browsing and paging stay silent; answers and game actions keep their cues." : "瀏覽與翻頁保持安靜；答題與遊戲操作仍保留提示音。")
                .font(.caption).foregroundStyle(Atlas.muted)
        }
    }

    private var learningPanel: some View {
        panel(en ? "Learning system" : "學習系統", symbol: "brain.head.profile", tint: Atlas.blue) {
            Label(en ? "Learn at your pace" : "按照自己的節奏", systemImage: "leaf").font(.headline)
            Text(en ? "Study the flag and both country names before continuing. Timed modes advance automatically." : "看清國旗與中英名稱後再繼續；限時模式則會自動前進。")
                .font(.subheadline).foregroundStyle(Atlas.muted)
            Divider().overlay(.white.opacity(0.08))
            Label(en ? "Spaced review" : "間隔複習", systemImage: "calendar.badge.clock").font(.headline)
            Text(en ? "Due intervals: 1 → 3 → 7 → 14 → 30 days. A mistake returns in 10 minutes." : "到期答對後：1 → 3 → 7 → 14 → 30 天；答錯則在 10 分鐘後再次複習。")
                .font(.subheadline).foregroundStyle(Atlas.muted)
        }
    }

    private var dataPanel: some View {
        panel(en ? "Answer history" : "答題資料", symbol: "externaldrive", tint: Atlas.coral) {
            Metric(value: "\(stats.stats.count)", label: en ? "Flags saved on this device" : "儲存在此裝置的國旗紀錄")
            Text(en ? "Clearing resets your passport and review schedule." : "清除後會重設探索護照與複習排程。")
                .font(.subheadline).foregroundStyle(Atlas.muted)
            Button(role: .destructive) { confirmClear = true } label: {
                Label(en ? "Clear all answer history" : "清除所有答題紀錄", systemImage: "trash").font(.headline).frame(maxWidth: .infinity)
            }.buttonStyle(AtlasButtonStyle(tint: Atlas.coral))
        }
    }

    private func panel<Content: View>(_ title: String, symbol: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(title, systemImage: symbol).font(.title3.bold()).foregroundStyle(tint)
            content()
        }.frame(maxWidth: .infinity, alignment: .leading).modifier(AtlasCard(tint: tint))
    }

    private func volumePicker(selection: Binding<VolumeLevel>, label: String) -> some View {
        Picker(label, selection: selection) {
            ForEach(VolumeLevel.allCases) { level in Text(volumeTitle(level)).tag(level) }
        }.pickerStyle(.segmented).accessibilityLabel(label)
    }

    private func volumeTitle(_ level: VolumeLevel) -> String {
        switch (level, en) {
        case (.high, true): "High"; case (.medium, true): "Medium"; case (.low, true): "Low"; case (.off, true): "Off"
        case (.high, false): "高"; case (.medium, false): "中"; case (.low, false): "低"; case (.off, false): "關"
        }
    }
}

#Preview { NavigationStack { SettingsView() }.environmentObject(AppSettings()).environmentObject(StatsStore()) }
