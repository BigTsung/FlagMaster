import SwiftUI

struct RecordsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.dismiss) private var dismiss
    @State private var countries: [Country] = (try? CountryRepository.load()) ?? []
    @State private var query = ""
    @State private var onlyMistakes = false
    private var en: Bool { settings.language == .english }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow(text: en ? "YOUR EXPLORER PASSPORT" : "每一次探索，都算數")
                        Text(en ? "A world of progress." : "把世界，一點點收集。")
                            .font(.system(.title, design: .rounded).bold())
                        HStack {
                            Metric(value: "\(stats.stats.count)/\(countries.count)", label: en ? "Explored" : "已探索")
                            Metric(value: "\(stats.mastered)", label: en ? "Mastered" : "熟悉國旗", color: Atlas.gold)
                        }
                        ProgressView(value: Double(stats.stats.count), total: Double(max(1, countries.count))).tint(Atlas.mint)
                        Text(en ? "Familiar: pass 3 due reviews in a row. Early practice does not advance the schedule." : "熟悉標準：連續通過 3 次到期作答；提前練習不會提升階段。")
                            .font(.caption).foregroundStyle(Atlas.muted)
                    }.modifier(AtlasCard(tint: Atlas.mint))
                    Picker(en ? "Show records" : "顯示紀錄", selection: $onlyMistakes) {
                        Text(en ? "All discoveries" : "所有探索").tag(false)
                        Text(en ? "Needs practice" : "待加強").tag(true)
                    }.pickerStyle(.segmented)
                    if ranked.isEmpty {
                        ContentUnavailableView {
                            Label(en ? "More discoveries ahead" : "新的發現，正等著你", systemImage: "globe.asia.australia")
                        } description: {
                            Text(query.isEmpty ? (en ? "Play a round to fill your passport." : "開始答題，讓你的探索護照留下足跡。") : (en ? "Try another country name." : "試試其他國家名稱。"))
                        }
                    } else {
                        HStack {
                            Eyebrow(text: en ? "PRACTICE PRIORITY" : "從最需要練習的開始", color: Atlas.muted)
                            Spacer()
                            Text("\(ranked.count)").font(.caption.monospacedDigit()).foregroundStyle(Atlas.muted)
                        }
                        LazyVStack(spacing: 12) {
                            ForEach(ranked, id: \.0.countryCode) { stat, country in
                                record(stat, country)
                            }
                        }
                    }
                }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(.white)
        .searchable(text: $query, prompt: en ? "Find a country" : "搜尋國家名稱")
        .navigationTitle(en ? "Passport" : "探索護照").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() }.tint(Atlas.mint) } }
        .toolbarBackground(Atlas.ink, for: .navigationBar)
    }

    private func record(_ stat: CountryStat, _ country: Country) -> some View {
        HStack(spacing: 14) {
            FlagImage(code: country.abb2).frame(width: 60, height: 42)
                .accessibilityHidden(false).accessibilityLabel(country.name(for: settings.language))
            VStack(alignment: .leading, spacing: 6) {
                Text(country.name(for: settings.language)).font(.subheadline.bold())
                Text(en ? country.cn : country.en).font(.caption).foregroundStyle(Atlas.muted)
                if let due = stat.nextReviewAt {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(due, style: .relative)
                    }.font(.caption2).foregroundStyle(Atlas.blue)
                } else { Text(en ? "Ready for review" : "可開始複習").font(.caption2).foregroundStyle(Atlas.gold) }
                ProgressView(value: stat.accuracy).tint(stat.accuracy >= 0.8 ? Atlas.mint : Atlas.gold)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 5) {
                Text(stat.accuracy, format: .percent.precision(.fractionLength(0)))
                    .font(.system(.headline, design: .rounded)).foregroundStyle(Atlas.mint)
                Text("\(stat.correctAnswers)/\(stat.totalAttempts)").font(.caption.monospacedDigit()).foregroundStyle(Atlas.muted)
            }
        }.modifier(AtlasCard())
    }

    private var ranked: [(CountryStat, Country)] {
        let byCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.abb2, $0) })
        return stats.stats.values.sorted {
            $0.accuracy == $1.accuracy ? $0.countryCode < $1.countryCode : $0.accuracy < $1.accuracy
        }.compactMap { stat in
            guard let country = byCode[stat.countryCode],
                  !onlyMistakes || stat.needsPractice,
                  query.isEmpty || country.cn.localizedCaseInsensitiveContains(query) || country.en.localizedCaseInsensitiveContains(query)
            else { return nil }
            return (stat, country)
        }
    }
}

#Preview { NavigationStack { RecordsView() }.environmentObject(AppSettings()).environmentObject(StatsStore()) }
