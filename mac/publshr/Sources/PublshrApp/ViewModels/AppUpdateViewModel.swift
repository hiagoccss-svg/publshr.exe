import AppKit
import Foundation

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
    @AppStorage("publshr.autoCheckUpdates") var autoCheckEnabled = true
    @AppStorage("publshr.autoInstallUpdates") var autoInstallEnabled = true

    private let service = AppUpdateService.shared
    private var checkTask: Task<Void, Never>?

    /// Poll interval for GitHub `live` channel (every push to main publishes there).
    private static let livePollSeconds: UInt64 = 180

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
        case .idle:
            return "Live · v\(AppReleaseConfig.installedLabel)"
        case .checking:
            return "Checking live channel…"
        case .upToDate:
            return "Live · v\(AppReleaseConfig.installedLabel)"
        case .available(let update):
            return "Update \(update.version) — downloading…"
        case .downloading(let progress):
            return "Downloading live build… \(Int(progress * 100))%"
        case .readyToInstall(let update):
            return autoInstallEnabled ? "Installing \(update.version)…" : "Ready to install \(update.version)"
        case .installing:
            return "Installing update — restarting…"
        case .failed(let message):
            return message
        }
    }

    func startAutomaticChecks() {
        guard autoCheckEnabled else { return }
        checkTask?.cancel()
        checkTask = Task {
            await performLiveSync()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.livePollSeconds * 1_000_000_000)
                await performLiveSync()
            }
        }
    }

    /// Check GitHub `live`, download if newer, install and restart — no Settings click.
    func performLiveSync() async {
        guard autoCheckEnabled else { return }
        if case .installing = phase { return }
        if case .downloading = phase { return }

        await checkForUpdates(silent: true)

        if autoInstallEnabled {
            if case .available = phase {
                await downloadUpdate()
            }
            if case .readyToInstall = phase {
                await installAndRestart()
            }
        }
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
            if !silent {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func downloadUpdate() async {
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
            phase = .failed(error.localizedDescription)
        }
    }

    func updateNow() async {
        if case .readyToInstall = phase {
            await installAndRestart()
            return
        }
        if case .available = phase {
            await downloadUpdate()
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
        await downloadUpdate()
        if case .readyToInstall = phase {
            await installAndRestart()
        }
    }

    func installAndRestart() async {
        if case .available = phase {
            await downloadUpdate()
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
            phase = .failed(error.localizedDescription)
        }
    }
}
