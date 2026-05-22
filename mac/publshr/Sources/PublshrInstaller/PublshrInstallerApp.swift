import SwiftUI
import AppKit

@main
struct PublshrInstallerApp: App {
    var body: some Scene {
        WindowGroup {
            InstallerRootView()
                .frame(minWidth: 520, minHeight: 420)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
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

    private let repo = ProcessInfo.processInfo.environment["PUBLSHR_REPO"] ?? "hiagoccss-svg/publshr.exe"
    private let liveURL: URL
    private let appDest = URL(fileURLWithPath: "/Applications/Publshr.app")
    private let sourceMarker = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/Publshr/install-source.tree")

    init() {
        liveURL = URL(string: "https://github.com/\(repo)/releases/download/live/Publshr-macos-aarch64.tar.gz")!
    }

    func startInstall() {
        Task { await runInstall() }
    }

    private func runInstall() async {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("publshr-install-\(UUID().uuidString)")
        do {
            try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

            let tree: URL
            if let bundled = loadBundledSourceTree() {
                phase = .installing
                progress = 0.5
                statusLine = "Installing from downloaded package…"
                tree = bundled
            } else {
                phase = .downloading
                progress = 0.05
                statusLine = "Downloading Publshr…"

                let archive = tmp.appendingPathComponent("Publshr-macos-aarch64.tar.gz")
                let (bytes, response) = try await URLSession.shared.download(from: liveURL)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw InstallerError.downloadFailed
                }
                try FileManager.default.moveItem(at: bytes, to: archive)
                progress = 0.45
                statusLine = "Extracting…"

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
            progress = 0.7
            statusLine = "Installing to Applications…"

            try installWithAdminPrivileges(from: sourceApp, to: appDest)
            progress = 1
            phase = .done
            statusLine = "Publshr is installed."

            try? FileManager.default.removeItem(at: tmp)
            NSWorkspace.shared.open(appDest)
        } catch {
            phase = .failed(error.localizedDescription)
            try? FileManager.default.removeItem(at: tmp)
        }
    }

    private func loadBundledSourceTree() -> URL? {
        guard let raw = try? String(contentsOf: sourceMarker, encoding: .utf8) else { return nil }
        let path = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return nil }
        let tree = URL(fileURLWithPath: path)
        return validateAppTree(tree) ? tree : nil
    }

    private func validateAppTree(_ tree: URL) -> Bool {
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

    private func findAppTree(in tmp: URL) -> URL? {
        guard let items = try? FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return nil
        }
        for item in items where item.hasDirectoryPath {
            if validateAppTree(item) { return item }
        }
        return nil
    }

    private func installWithAdminPrivileges(from source: URL, to dest: URL) throws {
        let script = """
        set -e
        rm -rf '\(dest.path)'
        ditto '\(source.path)' '\(dest.path)'
        chmod -R 755 '\(dest.path)'
        xattr -cr '\(dest.path)' 2>/dev/null || true
        """
        var error: NSDictionary?
        let apple = NSAppleScript(source: """
        do shell script "\(script.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """)
        guard apple?.executeAndReturnError(&error) != nil else {
            if let msg = error?[NSAppleScript.errorMessage] as? String {
                throw InstallerError.installFailed(msg)
            }
            throw InstallerError.installFailed("Administrator approval required.")
        }
    }
}

enum InstallerError: LocalizedError {
    case downloadFailed
    case extractFailed
    case invalidPackage
    case installFailed(String)

    var errorDescription: String? {
        switch self {
        case .downloadFailed: return "Could not download the latest Publshr build."
        case .extractFailed: return "Could not extract the download."
        case .invalidPackage: return "Downloaded package is missing Publshr.app."
        case .installFailed(let m): return m
        }
    }
}

struct InstallerRootView: View {
    @StateObject private var model = InstallerViewModel()

    var body: some View {
        ZStack {
            InstallerTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                content
                footer
            }
            .padding(32)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(InstallerTheme.accent)
            Text("Install Publshr")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(InstallerTheme.foreground)
            Text("Native macOS desktop — Swift, Supabase, enterprise chat")
                .font(.system(size: 13))
                .foregroundStyle(InstallerTheme.muted)
        }
        .padding(.bottom, 28)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch model.phase {
            case .welcome:
                Text("Publshr will be installed to your Applications folder. You can sign in, create a workspace, and use Touch ID on later launches.")
                    .font(.system(size: 13))
                    .foregroundStyle(InstallerTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            case .downloading, .installing:
                ProgressView(value: model.progress)
                    .progressViewStyle(.linear)
                Text(model.statusLine)
                    .font(.system(size: 12))
                    .foregroundStyle(InstallerTheme.muted)
            case .done:
                Label("Installation complete", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(InstallerTheme.accent)
            case .failed(let msg):
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundStyle(InstallerTheme.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(InstallerTheme.card)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(InstallerTheme.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var footer: some View {
        HStack {
            Spacer()
            switch model.phase {
            case .welcome:
                Button("Install") { model.startInstall() }
                    .buttonStyle(InstallerPrimaryButtonStyle())
            case .done:
                Button("Open Publshr") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Publshr.app"))
                    NSApp.terminate(nil)
                }
                .buttonStyle(InstallerPrimaryButtonStyle())
            case .failed:
                Button("Try again") { model.phase = .welcome }
                    .buttonStyle(InstallerPrimaryButtonStyle())
            default:
                EmptyView()
            }
        }
        .padding(.top, 24)
    }
}

struct InstallerPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .background(InstallerTheme.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
