import Foundation

public enum AppConfig {
    public static let appVersion = "0.1.0"
    public static let repoOwner = "hiagoccss-svg"
    public static let repoName = "publshr.exe"
    public static let defaultBranch = "cursor/add-makefile-and-install-4aa6"

    public static var repoHTTPS: String {
        "https://github.com/\(repoOwner)/\(repoName).git"
    }

    public static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Publshr", isDirectory: true)
    }

    public static var cloneDirectory: URL {
        supportDirectory.appendingPathComponent("repo", isDirectory: true)
    }

    public static var updateStatePath: URL {
        supportDirectory.appendingPathComponent("update-state.json")
    }

    public static var appSpaceDataPath: URL {
        supportDirectory.appendingPathComponent("app-space.json")
    }
}
