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
    @AppStorage("publshr.autoCheckUpdates") private var storedAutoCheck = true
    @AppStorage("publshr.autoInstallUpdates") private var storedAutoInstall = true

    private let service = AppUpdateService.shared
    private var checkTask: Task<Void, Never>?

    /// Poll interval for GitHub `live` channel (every push to main publishes there).
    private static let livePollSeconds: UInt64 = 60

    /// Live updates are always on — storage keys kept for migration only.
    var autoCheckEnabled: Bool {
        get { true }
        set { storedAutoCheck = true }
    }

    var autoInstallEnabled: Bool {
        get { true }
        set { storedAutoInstall = true }
    }

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
        if case .failed(let message) = phase { return message }
        return nil
    }

    var statusLine: String {
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
            return "Preparing version \(update.version)…"
        case .installing:
            return "Installing update…"
        case .failed(let message):
            return message
        }
    }

    /// Shown in Settings only when the user explicitly requested an update action.
    var settingsErrorMessage: String? {
        errorMessage
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
        case .upToDate:
            return "Check for updates"
        case .failed:
            return "Retry download and install"
        case .idle:
            return "Download and install latest"
        }
    }

    func startAutomaticChecks() {
        storedAutoCheck = true
        storedAutoInstall = true
        checkTask?.cancel()
        checkTask = Task {
            await performLiveSync()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.livePollSeconds * 1_000_000_000)
                await performLiveSync()
            }
        }
    }

    /// Background path: check, download, install — failures are logged only (no workspace banner).
    func performLiveSync() async {
        if case .installing = phase { return }
        if case .downloading = phase { return }

        await checkForUpdates(silent: true)
        if case .failed = phase {
            phase = .upToDate
            return
        }

        if case .available = phase {
            await downloadUpdate(silent: true)
        }
        if case .failed = phase {
            phase = .upToDate
            return
        }
        if case .readyToInstall = phase {
            await installAndRestart()
        }
    }

    /// Settings / menu: always check, download, and install (even if background sync is mid-flight).
    func installLiveUpdateNow() async {
        if case .installing = phase { return }
        if case .failed = phase { phase = .idle }
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

        do {
            if let update = try await service.checkForUpdate() {
                if case .readyToInstall = phase { return }
                phase = .available(update)
            } else {
                phase = .upToDate
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

        do {
            let archiveURL = try await service.download(update) { progress in
                Task { @MainActor in
                    if case .downloading = self.phase {
                        self.phase = .downloading(progress: progress)
                    }
                }
            }
            _ = try service.extract(archiveURL: archiveURL, version: update.version)
            phase = .readyToInstall(update)
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
        do {
            let updatesRoot = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Publshr/updates", isDirectory: true)
            let staging = updatesRoot.appendingPathComponent("staging-\(update.version)", isDirectory: true)
            try service.applyUpdate(treeURL: staging, parentPID: ProcessInfo.processInfo.processIdentifier)
            NSApplication.shared.terminate(nil)
        } catch {
            setFailure(error, silent: false)
        }
    }

    private func setFailure(_ error: Error, silent: Bool) {
        if silent {
            phase = .upToDate
            return
        }
        phase = .failed(error.localizedDescription)
    }
}
