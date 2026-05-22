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
    @Published var autoCheckEnabled = true

    private let service = AppUpdateService.shared
    private var checkTask: Task<Void, Never>?

    var hasPendingUpdate: Bool {
        switch phase {
        case .available, .readyToInstall:
            return true
        default:
            return false
        }
    }

    var statusLine: String {
        switch phase {
        case .idle:
            return "v\(AppReleaseConfig.installedLabel)"
        case .checking:
            return "Checking for updates…"
        case .upToDate:
            return "Up to date · v\(AppReleaseConfig.installedLabel)"
        case .available(let update):
            return "Update \(update.version) available"
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

    func startAutomaticChecks() {
        guard autoCheckEnabled else { return }
        checkTask?.cancel()
        checkTask = Task {
            await checkForUpdates(silent: true)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10 * 60 * 1_000_000_000)
                await checkForUpdates(silent: true)
            }
        }
    }

    func checkForUpdates(silent: Bool = false) async {
        if case .checking = phase { return }
        if !silent { phase = .checking }

        do {
            if let update = try await service.checkForUpdate() {
                if case .readyToInstall = phase {
                    return
                }
                phase = .available(update)
                if silent {
                    await downloadUpdate()
                }
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
        guard case .available(let update) = phase else { return }
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

    func installAndRestart() async {
        guard case .readyToInstall(let update) = phase else {
            if case .available = phase {
                await downloadUpdate()
                guard case .readyToInstall = phase else { return }
                await installAndRestart()
            }
            return
        }

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
