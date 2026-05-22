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
    @Published private(set) var syncNote: String?
    @AppStorage("publshr.autoCheckUpdates") private var storedAutoCheck = true
    @AppStorage("publshr.autoInstallUpdates") private var storedAutoInstall = true

    private let service = AppUpdateService.shared
    private var checkTask: Task<Void, Never>?
    private var syncInFlight = false

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
        nil
    }

    var statusLine: String {
        if let syncNote, !isActivelyUpdating {
            return syncNote
        }
        switch phase {
        case .idle, .upToDate:
            return "Version \(AppReleaseConfig.shortVersion) (build \(AppReleaseConfig.buildNumber)) · synced with GitHub"
        case .checking:
            return "Syncing with GitHub…"
        case .available:
            return "Downloading update…"
        case .downloading(let progress):
            return "Downloading update… \(Int(progress * 100))%"
        case .readyToInstall(let update):
            return "Preparing version \(update.version)…"
        case .installing:
            return "Installing update in place…"
        case .failed:
            return "Version \(AppReleaseConfig.shortVersion) (build \(AppReleaseConfig.buildNumber))"
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
            return "Syncing…"
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
        storedAutoCheck = true
        storedAutoInstall = true
        checkTask?.cancel()
        checkTask = Task {
            await performLiveSync(silent: true)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.livePollSeconds * 1_000_000_000)
                await performLiveSync(silent: true)
            }
        }
    }

    /// Background + manual: check GitHub live channel, download, install in place. Supabase sync runs in parallel via notification.
    func performLiveSync(silent: Bool = true) async {
        guard !syncInFlight else { return }
        if case .installing = phase { return }
        syncInFlight = true
        defer { syncInFlight = false }

        await checkForUpdates(silent: silent)
        if case .failed = phase {
            if silent {
                phase = .upToDate
                syncNote = nil
            }
            return
        }

        if case .available = phase {
            await downloadUpdate(silent: silent)
        }
        if case .failed = phase {
            if silent {
                phase = .upToDate
                syncNote = nil
            }
            return
        }
        if case .readyToInstall = phase {
            await installAndRestart()
        } else if case .upToDate = phase {
            if !silent {
                syncNote = "Already on the latest build."
            }
        }
    }

    /// Settings / menu: same in-place sync (no separate installer download).
    func installLiveUpdateNow() async {
        if case .installing = phase { return }
        if case .failed = phase { phase = .idle }
        syncNote = nil
        await performLiveSync(silent: false)
    }

    func syncLiveBuildIfNeeded() async {
        await performLiveSync(silent: true)
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
                if !silent { syncNote = "Already on the latest build." }
            }
        } catch {
            handleTransientFailure(error, silent: silent)
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
            service.recordAppliedLiveManifest(update)
            phase = .readyToInstall(update)
        } catch {
            handleTransientFailure(error, silent: silent)
        }
    }

    func updateNow() async {
        await performLiveSync(silent: false)
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
            if let err = error as? AppUpdateError, case .applyScriptMissing = err {
                phase = .failed(err.localizedDescription)
            } else {
                handleTransientFailure(error, silent: false)
            }
        }
    }

    private func handleTransientFailure(_ error: Error, silent: Bool) {
        let detail = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        service.appendSyncLog("sync note: \(detail)")
        phase = .upToDate
        if silent {
            syncNote = nil
        } else {
            syncNote = "Could not sync right now. Will retry automatically."
        }
    }
}
