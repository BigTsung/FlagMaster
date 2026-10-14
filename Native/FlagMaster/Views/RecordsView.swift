import SwiftUI

struct RecordsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.dismiss) private var dismiss
    @State private var countries: [Country] = (try? CountryRepository.load()) ?? []

    var body: some View {
        List(ranked, id: \.0.countryCode) { stat, country in
            HStack(spacing: 14) {
                FlagImage(code: country.abb2).frame(width: 64, height: 42)
                VStack(alignment: .leading) {
                    Text(country.name(for: settings.language)).font(.headline)
                    Text("\(stat.correctAnswers) / \(stat.totalAttempts)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(stat.accuracy, format: .percent.precision(.fractionLength(0))).font(.headline.monospacedDigit())
            }.padding(.vertical, 3)
        }
        .overlay { if ranked.isEmpty { ContentUnavailableView(settings.language == .english ? "No records yet" : "尚無答題紀錄", systemImage: "chart.bar") } }
        .navigationTitle(settings.language == .english ? "Records" : "答題紀錄")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(settings.language == .english ? "Done" : "完成") { dismiss() } } }
    }

    private var ranked: [(CountryStat, Country)] {
        let byCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.abb2, $0) })
        return stats.stats.values.sorted { $0.accuracy < $1.accuracy }.compactMap { stat in byCode[stat.countryCode].map { (stat, $0) } }
    }
}

#Preview("Records") {
    NavigationStack {
        RecordsView()
            .environmentObject(AppSettings())
            .environmentObject(StatsStore())
    }
}
