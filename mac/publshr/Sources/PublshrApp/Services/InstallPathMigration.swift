import AppKit
import Foundation

/// Moves Publshr off system `/Applications` so live updates never trigger administrator prompts.
enum InstallPathMigration {
    private static let declinedMigrationKey = "publshr.declinedUserApplicationsMigration"

    @MainActor
    static func offerMigrationFromSystemApplicationsIfNeeded(force: Bool = false) {
        guard InstallPathPolicy.isSystemApplicationsInstall(path: Bundle.main.bundleURL.path) else {
            return
        }
        if !force, UserDefaults.standard.bool(forKey: declinedMigrationKey) { return }

        let dest = InstallPathPolicy.userApplicationsApp
        let alert = NSAlert()
        alert.messageText = "Move Publshr for passwordless updates?"
        alert.informativeText = """
        This copy is in /Applications. macOS often asks for your password when updating apps there.

        Move to \(dest.path) instead? Your sign-in, Chat, and Spaces data stay in ~/Library/Application Support/Publshr.
        """
        alert.addButton(withTitle: "Move now")
        alert.addButton(withTitle: "Not now")

        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try copyBundle(to: dest)
                NSWorkspace.shared.open(dest)
                NSApp.terminate(nil)
            } catch {
                let errAlert = NSAlert()
                errAlert.messageText = "Could not move Publshr"
                errAlert.informativeText = error.localizedDescription
                errAlert.runModal()
            }
        } else {
            UserDefaults.standard.set(true, forKey: declinedMigrationKey)
        }
    }

    private static func copyBundle(to dest: URL) throws {
        let source = Bundle.main.bundleURL
        let parent = dest.deletingLastPathComponent()
        let fm = FileManager.default
        try fm.createDirectory(at: parent, withIntermediateDirectories: true)
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = [source.path, dest.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "InstallPathMigration",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Copy failed (ditto exit \(process.terminationStatus))."]
            )
        }
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
        let xattr = Process()
        xattr.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        xattr.arguments = ["-cr", dest.path]
        try? xattr.run()
        xattr.waitUntilExit()
    }
}
