import SwiftUI
import AppKit

@main
struct PublshrInstallerApp: App {
    @NSApplicationDelegateAdaptor(InstallerAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            InstallerRootView()
                .frame(width: 340, height: 400)
                .background(InstallerGlassBackdrop())
                .background(WindowConfigurator())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

final class InstallerAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            InstallerWindowStyle.apply(to: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        InstallerWindowStyle.apply(to: nsView.window)
    }
}

@MainActor
final class InstallerViewModel: ObservableObject {
    enum Phase: Equatable {
        case welcome
        case downloading
        case installing
        case done
        case failed(String)
    }

    @Published var phase: Phase = .welcome
    @Published var progress: Double = 0
    @Published var statusLine = ""
    @Published private(set) var hasBundledApp = false

    private let liveURL = URL(string: "https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-macos-aarch64.tar.gz")!
    let appDest: URL
    private let bundledSourceTree: URL?
    private let sourceMarker = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/Publshr/install-source.tree")

    init() {
        appDest = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/Publshr.app", isDirectory: true)
        bundledSourceTree = Self.discoverBundledSourceTree(marker: sourceMarker)
        hasBundledApp = bundledSourceTree != nil
    }

    var shouldAutoStart: Bool { hasBundledApp }

    private static func discoverBundledSourceTree(marker: URL) -> URL? {
        if let raw = try? String(contentsOf: marker, encoding: .utf8) {
            let path = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty {
                let tree = URL(fileURLWithPath: path)
                if validateAppTree(tree) { return tree }
            }
        }
        let installFolder = Bundle.main.bundleURL.deletingLastPathComponent()
        if validateAppTree(installFolder) { return installFolder }
        return nil
    }

    private static func validateAppTree(_ tree: URL) -> Bool {
        repairAppTreeIfNeeded(tree)
        let gui = tree.appendingPathComponent("Publshr.app/Contents/MacOS/Publshr")
        guard FileManager.default.fileExists(atPath: gui.path) else { return false }
        let stale = tree.appendingPathComponent("Publshr.app/Contents/MacOS/PublshrApp")
        if FileManager.default.fileExists(atPath: stale.path) { return false }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: gui.path),
           let size = attrs[.size] as? Int, size < 500_000 {
            return false
        }
        return true
    }

    func startInstall() {
        switch phase {
        case .downloading, .installing, .done:
            return
        case .failed:
            phase = .welcome
        case .welcome:
            break
        }
        Task { await runInstall() }
    }

    private func runInstall() async {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("publshr-install-\(UUID().uuidString)")
        do {
            try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

            let tree: URL
            if let bundled = bundledSourceTree {
                phase = .installing
                progress = 0.35
                statusLine = "Installing…"
                tree = bundled
            } else {
                phase = .downloading
                progress = 0.05
                statusLine = "Downloading…"

                let archive = tmp.appendingPathComponent("Publshr-macos-aarch64.tar.gz")
                let (bytes, response) = try await URLSession.shared.download(from: liveURL)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw InstallerError.downloadFailed
                }
                try FileManager.default.moveItem(at: bytes, to: archive)
                progress = 0.45
                statusLine = "Preparing…"

                let extract = Process()
                extract.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
                extract.arguments = ["-xzf", archive.path, "-C", tmp.path]
                try extract.run()
                extract.waitUntilExit()
                guard extract.terminationStatus == 0 else { throw InstallerError.extractFailed }

                guard let extracted = findAppTree(in: tmp) else { throw InstallerError.invalidPackage }
                tree = extracted
            }

            let sourceApp = tree.appendingPathComponent("Publshr.app")
            guard FileManager.default.fileExists(atPath: sourceApp.path) else {
                throw InstallerError.invalidPackage
            }

            phase = .installing
            progress = 0.75
            statusLine = "Installing…"

            try installApp(from: sourceApp, to: appDest)
            progress = 1
            phase = .done
            statusLine = "Done"

            try? FileManager.default.removeItem(at: tmp)
            NSWorkspace.shared.open(appDest)
            try? await Task.sleep(nanoseconds: 900_000_000)
            NSApp.terminate(nil)
        } catch {
            phase = .failed(error.localizedDescription)
            try? FileManager.default.removeItem(at: tmp)
        }
    }

    private static func repairAppTreeIfNeeded(_ tree: URL) {
        let app = tree.appendingPathComponent("Publshr.app")
        let gui = app.appendingPathComponent("Contents/MacOS/Publshr")
        let legacy = app.appendingPathComponent("Contents/MacOS/PublshrApp")
        guard FileManager.default.fileExists(atPath: legacy.path),
              !FileManager.default.fileExists(atPath: gui.path) else { return }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: legacy.path),
              let size = attrs[.size] as? Int, size >= 500_000 else { return }
        try? FileManager.default.copyItem(at: legacy, to: gui)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: gui.path)
        try? FileManager.default.removeItem(at: legacy)
        let cli = app.appendingPathComponent("Contents/MacOS/publshr")
        if FileManager.default.fileExists(atPath: cli.path) {
            try? FileManager.default.removeItem(at: cli)
        }
    }

    private func findAppTree(in tmp: URL) -> URL? {
        guard let items = try? FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return nil
        }
        for item in items where item.hasDirectoryPath {
            if Self.validateAppTree(item) { return item }
        }
        return nil
    }

    private func installApp(from source: URL, to dest: URL) throws {
        let parent = dest.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        if isUserWritableAppDestination(dest) {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = [source.path, dest.path]
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw InstallerError.installFailed("Could not install Publshr.")
            }
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
            clearQuarantine(dest)
            return
        }
        throw InstallerError.installFailed(
            "Cannot write to \(parent.path). Create ~/Applications or fix folder permissions."
        )
    }

    private func isUserWritableAppDestination(_ dest: URL) -> Bool {
        let parent = dest.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parent.path) {
            return FileManager.default.createFile(atPath: parent.appendingPathComponent(".write-test").path, contents: Data())
                && (try? FileManager.default.removeItem(at: parent.appendingPathComponent(".write-test"))) != nil
        }
        if FileManager.default.isWritableFile(atPath: parent.path) {
            return true
        }
        if FileManager.default.fileExists(atPath: dest.path) {
            return FileManager.default.isWritableFile(atPath: dest.path)
        }
        return false
    }

    private func clearQuarantine(_ dest: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-cr", dest.path]
        try? process.run()
        process.waitUntilExit()
    }
}

enum InstallerError: LocalizedError {
    case downloadFailed
    case extractFailed
    case invalidPackage
    case installFailed(String)

    var errorDescription: String? {
        switch self {
        case .downloadFailed: return "Could not download the app package."
        case .extractFailed: return "Could not prepare the download."
        case .invalidPackage: return "The package is missing Publshr.app."
        case .installFailed(let m): return m
        }
    }
}

struct InstallerRootView: View {
    @StateObject private var model = InstallerViewModel()
    @State private var didAutoStart = false

    var body: some View {
        ZStack {
            InstallerGlassBackdrop()
            VStack(spacing: 28) {
                branding
                glassPanel
            }
            .padding(36)
        }
        .onAppear {
            guard !didAutoStart, model.shouldAutoStart else { return }
            didAutoStart = true
            model.startInstall()
        }
    }

    private var branding: some View {
        VStack(spacing: 14) {
            Group {
                if let icon = InstallerBranding.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(InstallerTheme.accent)
                }
            }
            Text("Publshr")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(InstallerTheme.foreground)
        }
    }

    @ViewBuilder
    private var glassPanel: some View {
        VStack(spacing: 20) {
            switch model.phase {
            case .welcome:
                if !model.hasBundledApp {
                    Button("Install") { model.startInstall() }
                        .buttonStyle(InstallerPrimaryButtonStyle())
                } else {
                    ProgressView()
                        .controlSize(.regular)
                }
            case .downloading, .installing:
                ProgressView(value: model.progress)
                    .progressViewStyle(.linear)
                Text(model.statusLine)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(InstallerTheme.muted)
            case .done:
                ProgressView(value: 1)
                    .progressViewStyle(.linear)
                Label("Opening Publshr…", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(InstallerTheme.accent)
            case .failed(let msg):
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundStyle(InstallerTheme.error)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Try again") {
                    model.phase = .welcome
                    model.startInstall()
                }
                .buttonStyle(InstallerPrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .background { InstallerGlassCard() }
    }
}

struct InstallerPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 32)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .background(InstallerTheme.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
