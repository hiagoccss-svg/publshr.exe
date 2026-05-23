import AppKit
import Foundation

/// Opens standalone Publshr desktop companions (Electron) from the native IDE.
enum DesktopCompanionAppLauncher {
    enum Product: String {
        case mediaMonitoring = "Publshr Media Monitoring"

        var bundleName: String { "\(rawValue).app" }
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
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.publshr.media-monitoring") {
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
        }
    }
}
