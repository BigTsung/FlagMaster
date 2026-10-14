import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false
    private var en: Bool { settings.language == .english }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: en ? "MAKE YOURSELF AT HOME" : "找到舒服的探索節奏")
                        Text(en ? "Your journey, your way." : "你的旅程，你來決定。")
                            .font(.system(.title, design: .rounded).bold())
                    }.padding(.vertical, 8)
                    settingCard(en ? "Language" : "介面語言", symbol: "character.bubble", tint: Atlas.mint) {
                        Picker(en ? "Language" : "介面語言", selection: $settings.language) {
                            Text("繁體中文").tag(AppLanguage.traditionalChinese)
                            Text("English").tag(AppLanguage.english)
                        }.pickerStyle(.segmented)
                        Text(en ? "Country names appear in both languages after each answer." : "每次作答後，同時顯示中英文名稱，建立雙語記憶。")
                            .font(.caption).foregroundStyle(Atlas.muted)
                    }
                    settingCard(en ? "Atmosphere & feedback" : "氣氛與互動", symbol: "sparkles", tint: Atlas.gold) {
                        Toggle(en ? "Animated effects" : "動態視覺效果", isOn: $settings.animatedEffects).tint(Atlas.mint)
                        Text(en ? "Gentle motion and springy transitions. Respects Reduce Motion." : "開啟漂浮與彈性轉場；也會遵循系統的「減少動態效果」。")
                            .font(.caption).foregroundStyle(Atlas.muted)
                        Divider().overlay(.white.opacity(0.08))
                        Text(en ? "Background music" : "背景音樂").font(.subheadline.bold())
                        volumePicker(selection: $settings.musicVolume, label: en ? "Background music volume" : "背景音樂音量")
                        Text(en ? "A calm theme on the home screen and a light, playful loop during practice." : "首頁使用舒緩旋律；進入練習後切換成輕快、不催促的循環音樂。")
                            .font(.caption).foregroundStyle(Atlas.muted)
                        Divider().overlay(.white.opacity(0.08))
                        Text(en ? "Sound effects" : "互動音效").font(.subheadline.bold())
                        volumePicker(selection: $settings.soundVolume, label: en ? "Sound effect volume" : "互動音效音量")
                        Text(en ? "Soft cues for taps, answers, and completing a journey." : "按鈕、答題和完成旅程都有柔和提示音。")
                            .font(.caption).foregroundStyle(Atlas.muted)
                        Divider().overlay(.white.opacity(0.08))
                        Toggle(en ? "Haptic feedback" : "答題觸覺回饋", isOn: $settings.hapticsEnabled).tint(Atlas.mint)
                        Text(en ? "Feel a response to correct and incorrect answers on supported iPhones." : "在支援的 iPhone 上，用震動感受答對或答錯的回饋。")
                            .font(.caption).foregroundStyle(Atlas.muted)
                    }
                    settingCard(en ? "Learning rhythm" : "學習節奏", symbol: "leaf", tint: Atlas.blue) {
                        Text(en ? "Exploration and review wait for you." : "探索與複習，都等你準備好。").font(.subheadline.bold())
                        Text(en ? "Read both country names and study the flag, then tap Continue. Timed challenges advance automatically." : "看清國旗、讀出中英名稱，再點「繼續旅程」。限時挑戰則會自動前進。")
                            .font(.subheadline).foregroundStyle(Atlas.muted).lineSpacing(4)
                    }
                    settingCard(en ? "Spaced review" : "間隔複習", symbol: "calendar.badge.clock", tint: Atlas.gold) {
                        Text(en ? "Correct when due: 1 → 3 → 7 → 14 → 30 days. A mistake brings the flag back in 10 minutes." : "到期答對後：1 → 3 → 7 → 14 → 30 天；答錯則在 10 分鐘後再次複習。")
                            .font(.subheadline).foregroundStyle(Atlas.muted)
                        Text(en ? "Early practice counts toward your history, but does not advance the schedule. Familiar flags have passed 3 due attempts in a row." : "提前練習會計入紀錄，但不提升複習階段。連續通過 3 次到期作答後，列為熟悉國旗。")
                            .font(.caption).foregroundStyle(Atlas.muted)
                    }
                    settingCard(en ? "Answer history" : "答題資料", symbol: "externaldrive", tint: Atlas.coral) {
                        Text(en ? "Your passport stays on this device." : "探索紀錄儲存在這台裝置上。")
                            .font(.subheadline).foregroundStyle(Atlas.muted)
                        Button(role: .destructive) { confirmClear = true } label: {
                            Label(en ? "Clear all answer history" : "清除所有答題紀錄", systemImage: "trash")
                                .font(.subheadline.bold()).padding(.vertical, 10)
                        }.tint(Atlas.coral)
                    }
                    Text("FLAGMASTER · \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.system(.caption2, design: .monospaced)).tracking(2).foregroundStyle(Atlas.muted)
                        .frame(maxWidth: .infinity).padding(8)
                }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(.white)
        .navigationTitle(en ? "Settings" : "旅程設定").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() }.tint(Atlas.mint) } }
        .toolbarBackground(Atlas.ink, for: .navigationBar)
        .confirmationDialog(en ? "Clear all answer history?" : "要清除所有答題紀錄嗎？", isPresented: $confirmClear, titleVisibility: .visible) {
            Button(en ? "Clear history" : "清除紀錄", role: .destructive) { stats.clear() }
            Button(en ? "Cancel" : "取消", role: .cancel) {}
        } message: {
            Text(en ? "Your passport and review history will be reset. This cannot be undone." : "探索護照與錯題紀錄將歸零，清除後無法復原。")
        }
    }

    private func settingCard<Content: View>(_ title: String, symbol: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: symbol).font(.headline).foregroundStyle(tint)
            content()
        }.frame(maxWidth: .infinity, alignment: .leading).modifier(AtlasCard(tint: tint))
    }

    private func volumePicker(selection: Binding<VolumeLevel>, label: String) -> some View {
        Picker(label, selection: selection) {
            ForEach(VolumeLevel.allCases) { level in
                Text(volumeTitle(level)).tag(level)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(label)
    }

    private func volumeTitle(_ level: VolumeLevel) -> String {
        switch (level, en) {
        case (.high, true): "High"
        case (.medium, true): "Medium"
        case (.low, true): "Low"
        case (.off, true): "Off"
        case (.high, false): "高"
        case (.medium, false): "中"
        case (.low, false): "低"
        case (.off, false): "關"
        }
    }
}

#Preview { NavigationStack { SettingsView() }.environmentObject(AppSettings()).environmentObject(StatsStore()) }
