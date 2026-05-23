import AppKit
import Foundation

/// Opens standalone Publshr desktop companions from the native IDE.
/// Installs from GitHub releases when not present — no local repo required.
enum DesktopCompanionAppLauncher {
    enum Product: String, CaseIterable {
        case spaces = "Publshr Spaces"
        case mediaMonitoring = "Publshr Media Monitoring"
        case planner = "Publshr Planner"

        var bundleName: String { "\(rawValue).app" }

        var bundleIdentifier: String {
            switch self {
            case .spaces: return "com.publshr.spaces"
            case .mediaMonitoring: return "com.publshr.media-monitoring"
            case .planner: return "com.publshr.planner"
            }
        }

        var productSlug: String {
            switch self {
            case .spaces: return "spaces"
            case .mediaMonitoring: return "media-monitoring"
            case .planner: return "planner"
            }
        }

        var installScriptName: String? {
            switch self {
            case .mediaMonitoring: return "install-desktop-media-monitoring.sh"
            case .spaces: return "install-desktop-spaces.sh"
            case .planner: return nil
            }
        }
    }

    private static let repo = "hiagoccss-svg/publshr.exe"
    private static let branch = "main"

    static func liveInstallCommand(for product: Product) -> String {
        guard let script = product.installScriptName else {
            return "Planner ships on the desktop release channel — open Settings → Updates in Publshr or download from GitHub releases."
        }
        return "curl -fsSL \"https://raw.githubusercontent.com/\(repo)/refs/heads/\(branch)/\(script)\" | bash"
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
        guard product.installScriptName != nil else { return false }
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
        switch product {
        case .spaces:
            return """
            Install from the cloud (no repo on your Mac):

            \(liveInstallCommand(for: product))

            Then open “\(product.rawValue)” from Applications. Updates arrive automatically from GitHub.
            """
        case .mediaMonitoring:
            return """
            Install from the cloud (no repo on your Mac):

            \(liveInstallCommand(for: product))

            Then open “\(product.rawValue)” from Applications. Updates arrive automatically from GitHub.
            """
        case .planner:
            return """
            Install Publshr Planner from the desktop release channel, then open “\(product.rawValue)” from Applications.

            Dev: cd planner/desktop && npm install && npm run dev
            """
        }
    }
}
