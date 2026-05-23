import AppKit
import Foundation

/// Opens standalone Publshr desktop companions (Electron) from the native IDE.
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

    static func installHint(for product: Product) -> String {
        switch product {
        case .mediaMonitoring:
            return """
            Install Media Monitoring from the repo desktop bundle, then open “\(product.rawValue)” from Applications.

            Dev: cd desktop/media-monitoring && npm install && npm run dev
            """
        case .spaces:
            return """
            Install Spaces from the desktop bundle, then open “\(product.rawValue)” from Applications.

            Dev: cd desktop/spaces && npm install && npm run dev
            """
        }
    }
}
