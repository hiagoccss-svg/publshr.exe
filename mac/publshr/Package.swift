// swift-tools-version: 5.9
import PackageDescription

#if os(macOS)
let macAppTargets: [Target] = [
    .executableTarget(
        name: "PublshrApp",
        dependencies: [
            .product(name: "Supabase", package: "supabase-swift"),
        ],
        path: "Sources/PublshrApp",
        swiftSettings: [
            .unsafeFlags(["-Xfrontend", "-strict-concurrency=minimal"]),
        ],
        linkerSettings: [
            .linkedLibrary("sqlite3"),
        ]
    ),
    .executableTarget(
        name: "PublshrInstaller",
        path: "Sources/PublshrInstaller"
    ),
]
let macAppProducts: [Product] = [
    .executable(name: "PublshrApp", targets: ["PublshrApp"]),
    .executable(name: "PublshrInstaller", targets: ["PublshrInstaller"]),
]
#else
let macAppTargets: [Target] = []
let macAppProducts: [Product] = []
#endif

let package = Package(
    name: "publshr",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "publshr", targets: ["publshrCLI"]),
    ] + macAppProducts,
    dependencies: macAppTargets.isEmpty
        ? []
        : [
            .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
        ],
    targets: [
        .executableTarget(
            name: "publshrCLI",
            path: "Sources/publshrCLI"
        ),
    ] + macAppTargets
)
