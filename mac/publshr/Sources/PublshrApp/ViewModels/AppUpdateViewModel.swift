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
    @Published private(set) var githubStatusLine: String = "Waiting for first GitHub check…"
    @Published private(set) var cloudSyncLine: String = "Sign in to sync Chat and Spaces from Supabase"
    @Published private(set) var remoteManifest: LiveChannelManifest?
    @Published private(set) var backgroundSyncRunning = false
    @Published private(set) var backgroundSyncStep = "Waiting for first cycle…"
    @Published private(set) var backgroundSyncLogExcerpt = "No sync logs yet."
    @Published private(set) var lastBackgroundSyncCompletedAt: Date?
    @Published private(set) var nextBackgroundSyncAt: Date?
    @AppStorage("publshr.autoCheckUpdates") var autoCheckEnabled = true
    @AppStorage("publshr.autoInstallUpdates") var autoInstallEnabled = true

    private let service = AppUpdateService.shared
    private var checkTask: Task<Void, Never>?
    private var syncInFlight = false
    private var performCloudDataSync: (() async -> Void)?
    private var reportSupabaseSyncTask: ((_ running: Bool, _ step: String, _ needsAppUpdate: Bool, _ error: String?) async -> Void)?

    /// Poll interval for GitHub `live` channel (every push to main publishes there).
    private static let livePollSeconds: UInt64 = AppReleaseConfig.livePollIntervalSeconds

    var hasPendingUpdate: Bool {
        switch phase {
        case .available, .readyToInstall, .downloading, .installing, .checking:
            return true
        default:
            return false
        }
    }

    var isActivelyUpdating: Bool {
        if backgroundSyncRunning { return true }
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

    /// Settings-only summary — never shown in the main workspace footer (Cursor-style shell has no status bar).
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

    func configureBackgroundSync(
        performCloudDataSync: @escaping () async -> Void,
        reportSupabaseSyncTask: @escaping (_ running: Bool, _ step: String, _ needsAppUpdate: Bool, _ error: String?) async -> Void
    ) {
        self.performCloudDataSync = performCloudDataSync
        self.reportSupabaseSyncTask = reportSupabaseSyncTask
    }

    func startAutomaticChecks() {
        AppReleaseConfig.reconcileAppliedManifestWithBundle()
        checkTask?.cancel()
        scheduleNextBackgroundSync(after: 0)
        checkTask = Task {
            await performUnifiedBackgroundSync(force: true)
            while !Task.isCancelled {
                let interval = Self.livePollSeconds
                scheduleNextBackgroundSync(after: interval)
                try? await Task.sleep(nanoseconds: interval * 1_000_000_000)
                await performUnifiedBackgroundSync(force: false)
            }
        }
    }

    private func scheduleNextBackgroundSync(after seconds: UInt64) {
        nextBackgroundSyncAt = Date().addingTimeInterval(TimeInterval(seconds))
    }

    func stopAutomaticChecks() {
        checkTask?.cancel()
        checkTask = nil
    }

    /// GitHub live channel only (check → download → install). Prefer `performUnifiedBackgroundSync` for the 30s loop.
    func performLiveSync(forceGitHub: Bool = false) async {
        guard forceGitHub || autoCheckEnabled else { return }
        guard !syncInFlight else { return }
        if case .installing = phase { return }
        if case .downloading = phase { return }
        syncInFlight = true
        defer { syncInFlight = false }

        await checkForUpdates(silent: true)
        if case .failed = phase {
            return
        }

        if case .available(let update) = phase {
            guard liveUpdateHasVerifiedDigest(update) else {
                service.appendSyncLog("auto-install skipped: live update missing package digest")
                phase = .upToDate
                refreshGitHubStatusFromService()
                return
            }
            await downloadUpdate(silent: true)
        }
        if case .failed = phase {
            return
        }

        if case .readyToInstall = phase, autoInstallEnabled {
            await installAndRestart()
            return
        }

        if case .upToDate = phase {
            refreshGitHubStatusFromService()
        }
    }

    /// Every 30s: GitHub health + live update + Supabase data pull — no Settings tap required.
    func performUnifiedBackgroundSync(force: Bool) async {
        guard force || autoCheckEnabled else { return }
        guard !backgroundSyncRunning else { return }
        backgroundSyncRunning = true
        defer {
            backgroundSyncRunning = false
            lastBackgroundSyncCompletedAt = Date()
            refreshLogExcerpt()
        }

        var cycleError: String?
        let logSummary = LocalSyncLogReader.summarize()
        backgroundSyncLogExcerpt = logSummary.excerpt

        func report(running: Bool, step: String, needsUpdate: Bool, error: String?) async {
            backgroundSyncStep = step
            await reportSupabaseSyncTask?(running, step, needsUpdate, error)
        }

        await report(running: true, step: "Checking GitHub + Supabase reachability", needsUpdate: logSummary.suggestsAppUpdate, error: nil)
        await CloudPlatformHealth.shared.refresh()

        await report(running: true, step: "GitHub live (check · download · install)", needsUpdate: logSummary.suggestsAppUpdate, error: nil)
        await performLiveSync(forceGitHub: force)

        await report(running: true, step: "Supabase (Chat · Spaces · enterprise)", needsUpdate: hasPendingUpdate, error: nil)
        if let performCloudDataSync {
            await performCloudDataSync()
        } else {
            NotificationCenter.default.post(name: .publshrPerformCloudSync, object: nil)
        }

        refreshLogExcerpt()
        let afterLogs = LocalSyncLogReader.summarize()
        if afterLogs.suggestsFailure, cycleError == nil {
            cycleError = "See sync log below"
        }
        let needsUpdate = hasPendingUpdate || afterLogs.suggestsAppUpdate
        let outcome = needsUpdate ? "Update available or in progress" : "Up to date"
        backgroundSyncStep = "Idle · \(outcome) · \(Self.timeStamp())"
        await report(running: false, step: backgroundSyncStep, needsUpdate: needsUpdate, error: cycleError)
        lastSyncLine = "Background sync · \(outcome) · \(Self.timeStamp())"
    }

    private func refreshLogExcerpt() {
        backgroundSyncLogExcerpt = LocalSyncLogReader.summarize().excerpt
    }

    func recordCloudSync(summary: String) {
        cloudSyncLine = "\(summary) · \(Self.timeStamp())"
    }

    func refreshGitHubStatusFromService() {
        remoteManifest = service.lastRemoteManifest
        if let remote = remoteManifest {
            githubStatusLine = "Live channel · \(remote.detailLabel) · checked \(Self.timeStamp())"
        } else {
            githubStatusLine = "Up to date · build \(AppReleaseConfig.buildNumber) · \(AppReleaseConfig.liveShellTag) · checked \(Self.timeStamp())"
        }
        lastSyncLine = githubStatusLine
    }

    /// Settings / menu: force full check → download → in-place install.
    func installLiveUpdateNow() async {
        if case .installing = phase { return }
        phase = .idle
        lastSyncLine = "Syncing live channel…"
        await performUnifiedBackgroundSync(force: true)
    }

    func syncLiveBuildIfNeeded() async {
        await performUnifiedBackgroundSync(force: false)
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
                remoteManifest = service.lastRemoteManifest
                if silent {
                    lastSyncLine = "Update \(update.version) · \(AppReleaseConfig.liveShellTag) → remote — downloading…"
                    if let remote = remoteManifest {
                        githubStatusLine = "Update available · \(remote.detailLabel)"
                    }
                }
            } else {
                phase = .upToDate
                if silent {
                    refreshGitHubStatusFromService()
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
        let digest = update.packageDigest ?? service.lastRemoteManifest?.packageDigest
        AppReleaseConfig.recordInstalledLiveManifest(
            version: update.version,
            build: update.build,
            digest: digest
        )
        do {
            LocalDataLayout.ensureRootExists()
            let staging = LocalDataLayout.updatesDirectory
                .appendingPathComponent("staging-\(update.version)", isDirectory: true)
            try service.applyUpdate(treeURL: staging, parentPID: ProcessInfo.processInfo.processIdentifier)
            NSApplication.shared.terminate(nil)
        } catch {
            setFailure(error, silent: false)
        }
    }

    private func setFailure(_ error: Error, silent: Bool) {
        let detail = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        service.appendSyncLog("sync: \(detail)")
        phase = .failed(detail)
        if silent {
            lastSyncLine = "Update check failed · will retry (\(detail))"
        } else {
            lastSyncLine = detail
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

    /// Live channel installs require SHA-256 from `VERSION.txt` (never API-only fallback).
    private func liveUpdateHasVerifiedDigest(_ update: AvailableUpdate) -> Bool {
        guard update.tag == AppReleaseConfig.liveTag else { return true }
        guard let digest = update.packageDigest, !digest.isEmpty else { return false }
        return true
    }
}
