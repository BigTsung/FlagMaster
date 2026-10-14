import SwiftUI

@main
struct FlagMasterApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var stats = StatsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(stats)
                .preferredColorScheme(.dark)
        }
    }
}
