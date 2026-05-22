import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppUpdateViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case checking
        case upToDate
        case available(AvailableUpdate)
        case downloading(progress: Double)
        case readyToInstall(AvailableUpdate)
        case installing
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var lastSyncLine: String = "Waiting for first sync…"
    @AppStorage("publshr.autoCheckUpdates") var autoCheckEnabled = true
    @AppStorage("publshr.autoInstallUpdates") var autoInstallEnabled = true

    private let service = AppUpdateService.shared
    private var checkTask: Task<Void, Never>?

    /// Poll interval for GitHub `live` channel (every push to main publishes there).
    private static let livePollSeconds: UInt64 = 60

    var hasPendingUpdate: Bool {
        switch phase {
        case .available, .readyToInstall, .downloading, .installing, .checking:
            return true
        default:
            return false
        }
    }

    var isActivelyUpdating: Bool {
        switch phase {
        case .checking, .downloading, .installing:
            return true
        default:
            return false
        }
    }

    var canInstallNow: Bool {
        switch phase {
        case .readyToInstall, .available:
            return true
        default:
            return false
        }
    }

    var errorMessage: String? {
        nil
    }

    var statusLine: String {
        if !isActivelyUpdating, !lastSyncLine.isEmpty, lastSyncLine != "Waiting for first sync…" {
            return lastSyncLine
        }
        switch phase {
        case .idle, .upToDate:
            return "Version \(AppReleaseConfig.shortVersion) (build \(AppReleaseConfig.buildNumber))"
        case .checking:
            return "Checking for updates…"
        case .available:
            return "Downloading update…"
        case .downloading(let progress):
            return "Downloading update… \(Int(progress * 100))%"
        case .readyToInstall(let update):
            return "Ready to install \(update.version)"
        case .installing:
            return "Installing update…"
        case .failed(let message):
            return message
        }
    }

    /// Shown in Settings only for rare install failures (not network blips).
    var settingsErrorMessage: String? {
        if case .failed(let message) = phase { return message }
        return nil
    }

    var settingsActionTitle: String {
        switch phase {
        case .checking:
            return "Checking…"
        case .downloading:
            return "Downloading…"
        case .installing:
            return "Installing…"
        case .readyToInstall, .available:
            return "Install update now"
        case .upToDate, .idle, .failed:
            return "Sync now"
        }
    }

    func startAutomaticChecks() {
        autoCheckEnabled = true
        autoInstallEnabled = true
        checkTask?.cancel()
        checkTask = Task {
            await performLiveSync()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.livePollSeconds * 1_000_000_000)
                await performLiveSync()
            }
        }
    }

    func stopAutomaticChecks() {
        checkTask?.cancel()
        checkTask = nil
    }

    /// Background path: check, download, install in place (enterprise default).
    func performLiveSync() async {
        if case .installing = phase { return }
        if case .downloading = phase { return }

        await checkForUpdates(silent: true)
        if case .failed = phase {
            phase = .upToDate
            lastSyncLine = "Up to date · will retry sync"
            return
        }

        if case .available = phase {
            await downloadUpdate(silent: true)
        }
        if case .failed = phase {
            phase = .upToDate
            lastSyncLine = "Up to date · will retry sync"
            return
        }

        if case .readyToInstall = phase {
            await installAndRestart()
            return
        }

        if case .upToDate = phase {
            lastSyncLine = "Up to date · checked \(Self.timeStamp())"
        }
    }

    /// Settings / menu: always check, download, and install (even if background sync is mid-flight).
    func installLiveUpdateNow() async {
        if case .installing = phase { return }
        if case .failed = phase { phase = .idle }
        lastSyncLine = "Syncing live channel…"
        await updateNow()
    }

    func syncLiveBuildIfNeeded() async {
        await performLiveSync()
    }

    func checkForUpdates(silent: Bool = false) async {
        if case .checking = phase { return }
        if case .downloading = phase { return }
        if case .installing = phase { return }
        if !silent { phase = .checking }
        if silent { lastSyncLine = "Checking live channel…" }

        do {
            if let update = try await service.checkForUpdate() {
                if case .readyToInstall = phase { return }
                phase = .available(update)
                if silent {
                    lastSyncLine = "Update \(update.version) available — downloading…"
                }
            } else {
                phase = .upToDate
                if silent {
                    lastSyncLine = "Up to date · checked \(Self.timeStamp())"
                }
            }
        } catch {
            setFailure(error, silent: silent)
        }
    }

    func downloadUpdate(silent: Bool = false) async {
        let update: AvailableUpdate
        switch phase {
        case .available(let u):
            update = u
        case .readyToInstall:
            return
        default:
            return
        }

        phase = .downloading(progress: 0)
        if silent { lastSyncLine = "Downloading \(update.version)…" }

        do {
            let archiveURL = try await service.download(update) { progress in
                Task { @MainActor in
                    if case .downloading = self.phase {
                        self.phase = .downloading(progress: progress)
                    }
                }
            }
            _ = try service.extract(archiveURL: archiveURL, version: update.version)
            service.recordAppliedLiveManifest(update)
            phase = .readyToInstall(update)
            if silent { lastSyncLine = "Downloaded \(update.version) — installing…" }
        } catch {
            setFailure(error, silent: silent)
        }
    }

    func updateNow() async {
        if case .readyToInstall = phase {
            await installAndRestart()
            return
        }
        if case .available = phase {
            await downloadUpdate(silent: false)
            if case .readyToInstall = phase {
                await installAndRestart()
            }
            return
        }
        await checkForUpdates(silent: false)
        guard case .available = phase else {
            if case .readyToInstall = phase {
                await installAndRestart()
            }
            return
        }
        await downloadUpdate(silent: false)
        if case .readyToInstall = phase {
            await installAndRestart()
        }
    }

    func installAndRestart() async {
        if case .available = phase {
            await downloadUpdate(silent: false)
        }
        guard case .readyToInstall(let update) = phase else { return }

        phase = .installing
        lastSyncLine = "Installing \(update.version)…"
        do {
            let updatesRoot = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Publshr/updates", isDirectory: true)
            let staging = updatesRoot.appendingPathComponent("staging-\(update.version)", isDirectory: true)
            try service.applyUpdate(treeURL: staging, parentPID: ProcessInfo.processInfo.processIdentifier)
            NSApplication.shared.terminate(nil)
        } catch {
            if let err = error as? AppUpdateError, case .applyScriptMissing = err {
                phase = .failed(err.localizedDescription)
                lastSyncLine = err.localizedDescription
            } else {
                handleTransientFailure(error, silent: false)
            }
        }
    }

    private func setFailure(_ error: Error, silent: Bool) {
        service.appendSyncLog("sync: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)")
        phase = .upToDate
        if silent {
            lastSyncLine = "Up to date · will retry sync"
        } else {
            lastSyncLine = "Could not sync right now. Will retry automatically."
        }
    }

    private func handleTransientFailure(_ error: Error, silent: Bool) {
        setFailure(error, silent: silent)
    }

    private static func timeStamp() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: Date())
    }
}
