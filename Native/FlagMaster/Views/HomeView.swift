import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var sheet: Sheet?
    let start: (GameMode) -> Void

    enum Sheet: Identifiable { case settings, records; var id: Self { self } }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)
                VStack(spacing: 6) {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(.yellow, .orange)
                    Text(settings.language == .english ? "FLAG MASTER" : "我要成為國旗王")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text(settings.language == .english ? "How many flags can you recognize?" : "你能認出多少面國旗？")
                        .foregroundStyle(.white.opacity(0.65))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(GameMode.allCases) { mode in
                        Button { start(mode) } label: {
                            VStack(spacing: 12) {
                                Image(systemName: mode.symbol).font(.title)
                                Text(mode.title(settings.language)).font(.headline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 104)
                            .background(.white.opacity(mode == .review ? 0.10 : 0.15), in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.14)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 14) {
                    SecondaryButton(symbol: "chart.bar.fill", title: settings.language == .english ? "Records" : "紀錄") { sheet = .records }
                    SecondaryButton(symbol: "gearshape.fill", title: settings.language == .english ? "Settings" : "設定") { sheet = .settings }
                }
                Text(versionText).font(.caption).foregroundStyle(.white.opacity(0.42))
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
        .sheet(item: $sheet) { item in
            NavigationStack {
                if item == .settings { SettingsView() } else { RecordsView() }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "v\(version) (\(build))"
    }
}

private struct SecondaryButton: View {
    let symbol: String
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(.black.opacity(0.18), in: Capsule())
        }.buttonStyle(.plain)
    }
}

#Preview("Home – Traditional Chinese") {
    ZStack {
        AppBackground()
        HomeView { _ in }
            .environmentObject(AppSettings())
    }
}
