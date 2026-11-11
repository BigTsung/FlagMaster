import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false
    @State private var showPrivacyPolicy = false
    @State private var section: Section = .general

    private enum Section: String, CaseIterable, Identifiable {
        case general, audio, learning, data
        var id: Self { self }
    }

    var body: some View {
        ZStack {
            AppBackground()
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 16) {
                    Eyebrow(text: settings.language.text("GAME OPTIONS", "遊戲選項", ja: "ゲームオプション", ko: "게임 옵션"), color: Atlas.accent)
                    Text(settings.language.text("Make it your game", "打造你的遊戲體驗", ja: "自分好みにカスタマイズ", ko: "나에게 맞게 설정하기")).font(.system(.title2, design: .rounded).weight(.black))
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
        }.foregroundStyle(Atlas.text)
        .navigationTitle(settings.language.text("Settings", "旅程設定", ja: "設定", ko: "설정")).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(settings.language.text("Done", "完成", ja: "完了", ko: "완료")) { dismiss() }.tint(Atlas.mint) } }
        .toolbarBackground(Atlas.ink, for: .navigationBar)
        .modifier(GameScreen(title: settings.language.text("OPTIONS", "遊戲設定", ja: "ゲーム設定", ko: "게임 설정"), symbol: "gearshape.fill"))
        .alert(privacyTitle, isPresented: $showPrivacyPolicy) {
            Button(settings.language.text("Done", "完成", ja: "完了", ko: "완료"), role: .cancel) {}
        } message: {
            Text(settings.language.text(
                "\(settings.language.appName) stores your answer history, review progress, and settings on your device. The app does not send this data to us or use it for advertising or tracking. To delete your answer history and review progress, choose Clear all answer history.",
                "\(settings.language.appName) 將答題紀錄、複習進度和設定儲存在你的裝置上。App 不會將這些資料傳給我們，也不會用於廣告或追蹤。若要刪除答題紀錄及複習進度，請選擇「清除所有答題紀錄」。",
                ja: "\(settings.language.appName) は回答履歴、復習の進み具合、設定を端末に保存します。アプリはこれらのデータを送信せず、広告や追跡にも使用しません。回答履歴と復習の進み具合を削除するには「回答履歴をすべて削除」を選んでください。",
                ko: "\(settings.language.appName)는 응답 기록, 복습 진행 상황 및 설정을 기기에 저장합니다. 앱은 이 데이터를 당사에 전송하거나 광고 또는 추적에 사용하지 않습니다. 응답 기록과 복습 진행 상황을 삭제하려면 ‘모든 응답 기록 삭제’를 선택하세요."
            ))
        }
        .confirmationDialog(settings.language.text("Clear all answer history?", "要清除所有答題紀錄嗎？", ja: "回答履歴をすべて削除しますか？", ko: "모든 응답 기록을 삭제할까요?"), isPresented: $confirmClear, titleVisibility: .visible) {
            Button(settings.language.text("Clear history", "清除紀錄", ja: "履歴を削除", ko: "기록 삭제"), role: .destructive) { stats.clear() }
            Button(settings.language.text("Cancel", "取消", ja: "キャンセル", ko: "취소"), role: .cancel) {}
        } message: { Text(settings.language.text("Your passport and review history will be reset.", "探索護照與錯題紀錄將歸零。", ja: "探検パスポートと復習履歴がリセットされます。", ko: "탐험 여권과 복습 기록이 초기화됩니다.")) }
    }

    private var sectionPicker: some View {
        HStack(spacing: 8) {
            sectionButton(.general, title: settings.language.text("Game", "遊戲", ja: "ゲーム", ko: "게임"), icon: "gamecontroller.fill")
            sectionButton(.audio, title: settings.language.text("Audio", "音效", ja: "サウンド", ko: "오디오"), icon: "speaker.wave.2.fill")
            sectionButton(.learning, title: settings.language.text("Rules", "規則", ja: "ルール", ko: "규칙"), icon: "book.closed.fill")
            sectionButton(.data, title: settings.language.text("Save", "存檔", ja: "データ", ko: "저장 데이터"), icon: "externaldrive.fill")
        }
    }

    private func sectionButton(_ value: Section, title: String, icon: String) -> some View {
        Button { section = value } label: {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.system(size: 11, weight: .bold))
            }.foregroundStyle(section == value ? Atlas.gold : Atlas.muted)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .modifier(GamePanel(tint: section == value ? Atlas.gold : Atlas.accent, radius: 16))
        }.buttonStyle(GameNavigationButtonStyle(tint: Atlas.gold)).accessibilityAddTraits(section == value ? .isSelected : [])
    }

    private var generalPanel: some View {
        panel(settings.language.text("Interface", "介面", ja: "表示設定", ko: "화면 설정"), symbol: "character.bubble", tint: Atlas.mint) {
            Text(settings.language.text("Language", "介面語言", ja: "表示言語", ko: "표시 언어")).font(.headline)
            Picker(settings.language.text("Language", "介面語言", ja: "表示言語", ko: "표시 언어"), selection: $settings.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }.pickerStyle(.segmented)
            Divider().overlay(Atlas.text.opacity(0.08))
            Toggle(settings.language.text("Animated effects", "動態視覺效果", ja: "アニメーション効果", ko: "애니메이션 효과"), isOn: $settings.animatedEffects).tint(Atlas.mint)
            Toggle(settings.language.text("Haptic feedback", "答題觸覺回饋", ja: "触覚フィードバック", ko: "햅틱 피드백"), isOn: $settings.hapticsEnabled).tint(Atlas.mint)
        }
    }

    private var audioPanel: some View {
        panel(settings.language.text("Atmosphere & feedback", "氣氛與互動", ja: "音とフィードバック", ko: "사운드와 피드백"), symbol: "waveform", tint: Atlas.gold) {
            Text(settings.language.text("Background music", "背景音樂", ja: "BGM", ko: "배경 음악")).font(.headline)
            volumePicker(selection: $settings.musicVolume, label: settings.language.text("Music volume", "背景音樂音量", ja: "BGM の音量", ko: "배경 음악 볼륨"))
            Text(settings.language.text("Exploration ambience on the home screen; a stronger pulse during challenges.", "首頁使用探索氛圍；進入挑戰後切換成更有推進感的節奏。", ja: "ホームでは落ち着いた曲、チャレンジ中はテンポの速い曲が流れます。", ko: "홈에서는 잔잔한 음악, 도전 중에는 박진감 있는 음악이 재생됩니다."))
                .font(.caption).foregroundStyle(Atlas.muted)
            Divider().overlay(Atlas.text.opacity(0.08))
            Text(settings.language.text("Sound effects", "互動音效", ja: "効果音", ko: "효과음")).font(.headline)
            volumePicker(selection: $settings.soundVolume, label: settings.language.text("Sound volume", "互動音效音量", ja: "効果音の音量", ko: "효과음 볼륨"))
            Text(settings.language.text("Browsing and paging stay silent; answers and game actions keep their cues.", "瀏覽與翻頁保持安靜；答題與遊戲操作仍保留提示音。", ja: "閲覧やページ切り替えは無音です。回答やゲーム操作には効果音が鳴ります。", ko: "둘러보거나 페이지를 넘길 때는 소리가 나지 않으며, 답변과 게임 조작에는 효과음이 재생됩니다."))
                .font(.caption).foregroundStyle(Atlas.muted)
        }
    }

    private var learningPanel: some View {
        panel(settings.language.text("Learning system", "學習系統", ja: "学習のしくみ", ko: "학습 방식"), symbol: "brain.head.profile", tint: Atlas.blue) {
            Label(settings.language.text("Learn at your pace", "按照自己的節奏", ja: "自分のペースで学ぼう", ko: "내 속도로 학습하기"), systemImage: "leaf").font(.headline)
            Text(settings.language.text("Study the flag and both country names before continuing. Timed modes advance automatically.", "看清國旗與中英名稱後再繼續；限時模式則會自動前進。", ja: "国旗と国名を確認してから次に進みます。時間制限のあるモードでは自動で進みます。", ko: "국기와 나라 이름을 확인한 뒤 다음으로 넘어갑니다. 시간 제한 모드에서는 자동으로 넘어갑니다."))
                .font(.subheadline).foregroundStyle(Atlas.muted)
            Divider().overlay(Atlas.text.opacity(0.08))
            Label(settings.language.text("Spaced review", "間隔複習", ja: "間隔復習", ko: "간격 복습"), systemImage: "calendar.badge.clock").font(.headline)
            Text(settings.language.text("Due intervals: 1 → 3 → 7 → 14 → 30 days. A mistake returns in 10 minutes.", "到期答對後：1 → 3 → 7 → 14 → 30 天；答錯則在 10 分鐘後再次複習。", ja: "正解後の復習間隔は 1 → 3 → 7 → 14 → 30 日です。不正解なら 10 分後に復習します。", ko: "정답 후 복습 간격은 1 → 3 → 7 → 14 → 30일입니다. 오답은 10분 후에 복습합니다."))
                .font(.subheadline).foregroundStyle(Atlas.muted)
        }
    }

    private var privacyTitle: String {
        settings.language.text("Privacy policy", "隱私權政策", ja: "プライバシーポリシー", ko: "개인정보 처리방침")
    }

    private var dataPanel: some View {
        panel(settings.language.text("Answer history", "答題資料", ja: "回答履歴", ko: "응답 기록"), symbol: "externaldrive", tint: Atlas.coral) {
            Metric(value: "\(stats.stats.count)", label: settings.language.text("Flags saved on this device", "儲存在此裝置的國旗紀錄", ja: "この端末に記録した国旗", ko: "이 기기에 저장된 국기"))
            Text(settings.language.text("Clearing resets your passport and review schedule.", "清除後會重設探索護照與複習排程。", ja: "削除すると、探検パスポートと復習予定がリセットされます。", ko: "삭제하면 탐험 여권과 복습 일정이 초기화됩니다."))
                .font(.subheadline).foregroundStyle(Atlas.muted)
            Button(role: .destructive) { confirmClear = true } label: {
                Label(settings.language.text("Clear all answer history", "清除所有答題紀錄", ja: "回答履歴をすべて削除", ko: "모든 응답 기록 삭제"), systemImage: "trash").font(.headline).frame(maxWidth: .infinity)
            }.buttonStyle(AtlasButtonStyle(tint: Atlas.coral))
            Button { showPrivacyPolicy = true } label: {
                Label(privacyTitle, systemImage: "hand.raised")
            }.tint(Atlas.mint)
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
        switch level {
        case .high: settings.language.text("High", "高", ja: "高", ko: "높음")
        case .medium: settings.language.text("Medium", "中", ja: "中", ko: "중간")
        case .low: settings.language.text("Low", "低", ja: "低", ko: "낮음")
        case .off: settings.language.text("Off", "關", ja: "オフ", ko: "끄기")
        }
    }
}

#Preview { AppPreview { NavigationStack { SettingsView() } } }
