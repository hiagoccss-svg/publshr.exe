import Foundation

/// User-owned install paths — passwordless live updates (ClickUp-style desktop policy).
enum InstallPathPolicy {
    static var userApplicationsApp: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/Publshr.app", isDirectory: true)
    }

    static var systemApplicationsApp: URL {
        URL(fileURLWithPath: "/Applications/Publshr.app", isDirectory: true)
    }

    static func isUserUpdatable(path: String) -> Bool {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        let parent = url.deletingLastPathComponent()
        let fm = FileManager.default
        try? fm.createDirectory(at: parent, withIntermediateDirectories: true)
        if !fm.isWritableFile(atPath: parent.path) { return false }
        if fm.fileExists(atPath: url.path) {
            if fm.isWritableFile(atPath: url.path) { return true }
            let probe = url.appendingPathComponent(".publshr-write-test")
            return (try? Data().write(to: probe)) != nil && (try? fm.removeItem(at: probe)) != nil
        }
        let probe = parent.appendingPathComponent(".publshr-write-test")
        return (try? Data().write(to: probe)) != nil && (try? fm.removeItem(at: probe)) != nil
    }

    /// Target for in-place live updates — never requires administrator approval.
    static func resolvedLiveUpdateTarget(runningBundlePath: String) -> String {
        if isUserUpdatable(path: runningBundlePath) {
            return runningBundlePath
        }
        return userApplicationsApp.path
    }
}
