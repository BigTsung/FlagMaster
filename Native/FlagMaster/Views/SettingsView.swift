import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        Form {
            Section(settings.language == .english ? "Language" : "語言") {
                Picker("", selection: $settings.language) {
                    Text("繁體中文").tag(AppLanguage.traditionalChinese)
                    Text("English").tag(AppLanguage.english)
                }.pickerStyle(.segmented)
            }
            Section(settings.language == .english ? "Music" : "音樂") { volumePicker($settings.musicVolume) }
            Section(settings.language == .english ? "Sound Effects" : "音效") { volumePicker($settings.soundVolume) }
            Section {
                Button(settings.language == .english ? "Clear review data" : "清除錯題紀錄", role: .destructive) { confirmClear = true }
            }
        }
        .navigationTitle(settings.language == .english ? "Settings" : "設定")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(settings.language == .english ? "Done" : "完成") { dismiss() } } }
        .confirmationDialog(settings.language == .english ? "Clear all answer history?" : "要清除所有答題紀錄嗎？", isPresented: $confirmClear) {
            Button(settings.language == .english ? "Clear" : "清除", role: .destructive) { stats.clear() }
        }
    }

    private func volumePicker(_ selection: Binding<VolumeLevel>) -> some View {
        Picker("", selection: selection) {
            ForEach(VolumeLevel.allCases) { level in Text(label(level)).tag(level) }
        }.pickerStyle(.segmented)
    }

    private func label(_ level: VolumeLevel) -> String {
        if settings.language == .english { return level.rawValue.capitalized }
        return switch level { case .high: "高"; case .medium: "中"; case .low: "低"; case .off: "關" }
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettings())
            .environmentObject(StatsStore())
    }
}
