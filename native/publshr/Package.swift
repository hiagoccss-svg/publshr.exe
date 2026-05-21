// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "publshr",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "publshr", targets: ["publshr"]),
        .executable(name: "Publshr", targets: ["PublshrApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.20.0"),
    ],
    targets: [
        .executableTarget(
            name: "publshr",
            path: "Sources/publshr"
        ),
        .target(
            name: "PublshrCore",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "Sources/PublshrCore",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "PublshrApp",
            dependencies: ["PublshrCore"],
            path: "Sources/PublshrApp",
            // Supabase v0.3 uses RootView/AppShellView. App Space + legacy Git sync UI stay in-tree but are not built yet.
            exclude: [
                "ContentView.swift",
                "AppSpaceModel.swift",
                "AppSpace",
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI", .when(platforms: [.macOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedFramework("LocalAuthentication", .when(platforms: [.macOS])),
            ]
        ),
    ]
)
