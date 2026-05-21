// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "publshr",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "publshr", targets: ["publshr"]),
    ],
    targets: [
        .executableTarget(name: "publshr"),
    ]
)
