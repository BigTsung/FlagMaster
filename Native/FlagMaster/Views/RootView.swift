import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @State private var activeMode: GameMode?

    var body: some View {
        ZStack {
            AppBackground()
            if let activeMode {
                GameView(mode: activeMode, stats: stats, settings: settings) { self.activeMode = nil }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                HomeView { mode in
                    withAnimation(.easeInOut(duration: 0.25)) { activeMode = mode }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: activeMode)
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.035, green: 0.075, blue: 0.16), Color(red: 0.10, green: 0.20, blue: 0.34)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle().fill(.cyan.opacity(0.12)).frame(width: 320).blur(radius: 20).offset(x: 130, y: -110)
        }
    }
}

#Preview("App Root") {
    RootView()
        .environmentObject(AppSettings())
        .environmentObject(StatsStore())
}
