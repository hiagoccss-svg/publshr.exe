import Foundation

/// Writes uncaught exception details to Application Support for enterprise diagnostics.
enum AppCrashReporter {
    private static let installed = NSLock()
    private static var didInstall = false

    static func install() {
        installed.lock()
        defer { installed.unlock() }
        guard !didInstall else { return }
        didInstall = true
        NSSetUncaughtExceptionHandler(publshrUncaughtExceptionHandler)
    }

    static func crashLogURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Publshr/crashes", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("last-crash.log")
    }
}

/// C-compatible handler (must not capture context).
private func publshrUncaughtExceptionHandler(_ exception: NSException) {
    let log = AppCrashReporter.crashLogURL()
    let header = "=== Uncaught exception \(ISO8601DateFormatter().string(from: Date())) ===\n"
    let body = """
    \(header)
    Name: \(exception.name.rawValue)
    Reason: \(exception.reason ?? "unknown")
    \(exception.callStackSymbols.joined(separator: "\n"))
    """
    if let data = body.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: log.path) {
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        } else {
            try? data.write(to: log)
        }
    }
}
