import AppKit
import Foundation

/// Opens standalone Publshr desktop companions (Electron) from the native IDE.
/// Product names match `shared/enterprise/products.ts` and CI `deliver-desktop.yml`.
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
        case .spaces:
            return """
            Install Publshr Spaces from the desktop release channel, then open “\(product.rawValue)” from Applications.

            Dev: cd desktop/spaces && npm install && npm run dev
            """
        case .mediaMonitoring:
            return """
            Install Publshr Media Monitoring from the desktop release channel, then open “\(product.rawValue)” from Applications.

            Dev: cd desktop/media-monitoring && npm install && npm run dev
            """
        case .planner:
            return """
            Install Publshr Planner from the desktop release channel, then open “\(product.rawValue)” from Applications.

            Dev: cd planner/desktop && npm install && npm run dev
            """
        }
    }
}
