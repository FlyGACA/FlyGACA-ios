// swift-tools-version: 5.9
// FlyGACAKit — the shared engine behind every Fly GACA App Store app (PPL, ELPT,
// AIP, and the wave-2 certificates). Each app target is a paper-thin shell over
// this package; see apple/ARCHITECTURE.md for the target graph and rules.
//
// Dependency direction (enforced by the target declarations below):
//   CoreModels ← StudyEngines / ContentKit / AppServices ← PersistenceKit ← FeatureUI
// The pure targets have ZERO external dependencies so `swift build` / `swift test`
// run instantly with no SDK downloads. Firebase/RevenueCat land later in a separate
// PlatformLive target (Phase 4) — never in these targets.
//
// macOS is listed only so the package builds and tests from the command line;
// the shipping platform is iOS 17+.
import PackageDescription

let package = Package(
    name: "FlyGACAKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreModels", targets: ["CoreModels"]),
        .library(name: "StudyEngines", targets: ["StudyEngines"]),
        .library(name: "ContentKit", targets: ["ContentKit"]),
        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
        .library(name: "AppServices", targets: ["AppServices"]),
        .library(name: "FeatureUI", targets: ["FeatureUI"]),
    ],
    targets: [
        .target(name: "CoreModels"),
        .target(name: "StudyEngines", dependencies: ["CoreModels"]),
        .target(name: "ContentKit", dependencies: ["CoreModels"]),
        .target(name: "PersistenceKit", dependencies: ["CoreModels", "StudyEngines"]),
        .target(name: "AppServices", dependencies: ["CoreModels"]),
        .target(
            name: "FeatureUI",
            dependencies: ["CoreModels", "StudyEngines", "ContentKit", "PersistenceKit", "AppServices"]
        ),
        .testTarget(name: "CoreModelsTests", dependencies: ["CoreModels"]),
        .testTarget(name: "StudyEnginesTests", dependencies: ["StudyEngines"]),
        .testTarget(name: "ContentKitTests", dependencies: ["ContentKit"]),
        .testTarget(
            name: "PersistenceKitTests",
            dependencies: ["PersistenceKit", "CoreModels", "StudyEngines"]
        ),
    ]
)
