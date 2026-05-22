// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "publshr",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "publshr", targets: ["publshrCLI"]),
        .executable(name: "PublshrApp", targets: ["PublshrApp"]),
        .executable(name: "PublshrInstaller", targets: ["PublshrInstaller"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "publshrCLI",
            path: "Sources/publshrCLI"
        ),
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
)
