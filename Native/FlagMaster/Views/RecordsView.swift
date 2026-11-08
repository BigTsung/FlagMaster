import SwiftUI

struct RecordsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.dismiss) private var dismiss
    @State private var countries: [Country] = (try? CountryRepository.load()) ?? []
    @State private var onlyMistakes = false
    @State private var page = 0
    private let pageSize = 4
    private var pageCount: Int { max(1, Int(ceil(Double(ranked.count) / Double(pageSize)))) }
    private var pageRecords: [(CountryStat, Country)] { Array(ranked.dropFirst(min(page, pageCount - 1) * pageSize).prefix(pageSize)) }

    var body: some View {
        ZStack {
            AppBackground()
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Eyebrow(text: settings.language.text("PLAYER RECORDS", "玩家紀錄", ja: "プレイヤーの記録", ko: "플레이어 기록"), color: Atlas.gold)
                            Text(settings.language.text("Your trophy room", "你的榮耀戰績", ja: "チャレンジの記録", ko: "나의 도전 기록")).font(.system(.title2, design: .rounded).weight(.black))
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(stats.stats.count)/\(countries.count)").font(.title2.bold()).foregroundStyle(Atlas.mint)
                            Text(settings.language.text("explored", "已探索", ja: "発見済み", ko: "발견 완료")).font(.caption).foregroundStyle(Atlas.muted)
                        }
                    }
                    HStack(spacing: 16) {
                        Image(systemName: "trophy.fill").font(.system(size: 42)).foregroundStyle(Atlas.gold).shadow(color: Atlas.gold.opacity(0.4), radius: 12)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(settings.language.text("WORLD DISCOVERY", "世界探索進度", ja: "世界の探索状況", ko: "세계 탐험 진행률")).font(.system(size: 12, weight: .black, design: .rounded))
                            ProgressView(value: Double(stats.stats.count), total: Double(max(1, countries.count))).tint(Atlas.gold)
                        }
                    }.padding(18).modifier(GamePanel(tint: Atlas.gold))
                    Picker(settings.language.text("Show records", "顯示紀錄", ja: "記録の表示", ko: "기록 보기"), selection: $onlyMistakes) {
                        Text(settings.language.text("All", "所有探索", ja: "すべて", ko: "전체")).tag(false); Text(settings.language.text("Practice", "待加強", ja: "要練習", ko: "연습 필요")).tag(true)
                    }.pickerStyle(.segmented).onChange(of: onlyMistakes) { _, _ in page = 0 }
                    if pageRecords.isEmpty {
                        ContentUnavailableView(settings.language.text("More discoveries ahead", "新的發現，正等著你", ja: "新しい発見が待っています", ko: "새로운 발견이 기다리고 있어요"), systemImage: "globe.asia.australia")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 8) { ForEach(pageRecords, id: \.0.countryCode) { stat, country in record(stat, country) } }
                        Spacer(minLength: 0)
                        pager
                    }
                }.padding(20).frame(maxWidth: 700, maxHeight: .infinity).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(.white)
        .navigationTitle(settings.language.text("Passport", "探索護照", ja: "探検パスポート", ko: "탐험 여권")).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(settings.language.text("Done", "完成", ja: "完了", ko: "완료")) { dismiss() }.tint(Atlas.mint) } }
        .toolbarBackground(Atlas.ink, for: .navigationBar)
        .modifier(GameScreen(title: settings.language.text("TROPHY ROOM", "戰績殿堂", ja: "トロフィールーム", ko: "트로피 전시실"), symbol: "trophy.fill", tint: Atlas.gold))
    }

    private var pager: some View {
        HStack {
            Button { page = max(0, page - 1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 40) }
                .buttonStyle(AtlasPressStyle(sound: nil)).disabled(page == 0)
            Spacer(); Text("\(page + 1) / \(pageCount)").font(.caption.monospacedDigit()).foregroundStyle(Atlas.muted); Spacer()
            Button { page = min(pageCount - 1, page + 1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 40) }
                .buttonStyle(AtlasPressStyle(sound: nil)).disabled(page >= pageCount - 1)
        }.padding(.horizontal, 8).background(Atlas.panel, in: Capsule())
    }

    private func record(_ stat: CountryStat, _ country: Country) -> some View {
        HStack(spacing: 12) {
            FlagImage(code: country.abb2).frame(width: 58, height: 38)
            VStack(alignment: .leading, spacing: 4) {
                Text(country.name(for: settings.language)).font(.subheadline.bold())
                ProgressView(value: stat.accuracy).tint(stat.accuracy >= 0.8 ? Atlas.mint : Atlas.gold)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 3) {
                Text(stat.accuracy, format: .percent.precision(.fractionLength(0))).font(.headline).foregroundStyle(Atlas.mint)
                Text("\(stat.correctAnswers)/\(stat.totalAttempts)").font(.caption.monospacedDigit()).foregroundStyle(Atlas.muted)
            }
        }.padding(14).modifier(GamePanel(tint: stat.accuracy >= 0.8 ? Atlas.mint : Atlas.gold, radius: 18))
    }

    private var ranked: [(CountryStat, Country)] {
        let byCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.abb2, $0) })
        return stats.stats.values.sorted {
            $0.accuracy == $1.accuracy ? $0.countryCode < $1.countryCode : $0.accuracy < $1.accuracy
        }.compactMap { stat in
            guard let country = byCode[stat.countryCode], !onlyMistakes || stat.needsPractice else { return nil }
            return (stat, country)
        }
    }
}

#Preview { NavigationStack { RecordsView() }.environmentObject(AppSettings()).environmentObject(StatsStore()) }
