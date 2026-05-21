// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "publshr",
    products: [
        .executable(name: "publshr", targets: ["publshr"]),
        .executable(name: "Publshr", targets: ["PublshrApp"]),
    ],
    targets: [
        .executableTarget(
            name: "publshr",
            path: "Sources/publshr"
        ),
        .target(
            name: "PublshrCore",
            path: "Sources/PublshrCore"
        ),
        .executableTarget(
            name: "PublshrApp",
            dependencies: ["PublshrCore"],
            path: "Sources/PublshrApp",
            linkerSettings: [
                .linkedFramework("SwiftUI", .when(platforms: [.macOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
            ]
        ),
    ]
)
