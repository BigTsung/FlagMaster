// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FlagMasterCore",
    platforms: [.macOS(.v13)],
    products: [.library(name: "FlagMasterCore", targets: ["FlagMasterCore"])],
    targets: [
        .target(name: "FlagMasterCore", path: "FlagMaster",
                exclude: ["App", "Views", "Assets.xcassets", "Resources", "Services/FlagImage.swift", "Services/AudioManager.swift"],
                sources: ["Models", "Services/AppSettings.swift", "Services/CountryRepository.swift", "Services/StatsStore.swift", "ViewModels"]),
        .testTarget(name: "FlagMasterCoreTests", dependencies: ["FlagMasterCore"], path: "Tests")
    ]
)
