import AppKit
import Foundation

/// Opens standalone Publshr desktop companions (Electron) from the native IDE.
/// Installs from GitHub releases when not present — no local repo required.
enum DesktopCompanionAppLauncher {
    enum Product: String {
        case mediaMonitoring = "Publshr Media Monitoring"
        case spaces = "Publshr Spaces"

        var bundleName: String { "\(rawValue).app" }

        var bundleIdentifier: String {
            switch self {
            case .mediaMonitoring: return "com.publshr.media-monitoring"
            case .spaces: return "com.publshr.spaces"
            }
        }

        var productSlug: String {
            switch self {
            case .mediaMonitoring: return "media-monitoring"
            case .spaces: return "spaces"
            }
        }

        var installScriptName: String {
            switch self {
            case .mediaMonitoring: return "install-desktop-media-monitoring.sh"
            case .spaces: return "install-desktop-spaces.sh"
            }
        }
    }

    private static let repo = "hiagoccss-svg/publshr.exe"
    private static let branch = "main"

    static func liveInstallCommand(for product: Product) -> String {
        "curl -fsSL \"https://raw.githubusercontent.com/\(repo)/refs/heads/\(branch)/\(product.installScriptName)\" | bash"
    }

    @discardableResult
    static func open(_ product: Product) -> Bool {
        let candidates = [
            URL(fileURLWithPath: "/Applications/\(product.bundleName)"),
            URL(fileURLWithPath: NSHomeDirectory() + "/Applications/\(product.bundleName)"),
        ]
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.open(url)
            return true
        }
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: product.bundleIdentifier) {
            NSWorkspace.shared.open(appURL)
            return true
        }
        return false
    }

    /// Download and install from GitHub `production` release, then open.
    @discardableResult
    static func installFromLive(_ product: Product) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", liveInstallCommand(for: product)]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }
        guard process.terminationStatus == 0 else { return false }
        return open(product)
    }

    @discardableResult
    static func openOrInstall(_ product: Product) -> Bool {
        if open(product) { return true }
        return installFromLive(product)
    }

    static func installHint(for product: Product) -> String {
        """
        Install from the cloud (no repo on your Mac):

        \(liveInstallCommand(for: product))

        Then open “\(product.rawValue)” from Applications. Updates arrive automatically from GitHub.
        """
    }
}
