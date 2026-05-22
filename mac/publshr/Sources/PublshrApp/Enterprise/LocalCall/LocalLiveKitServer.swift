import Darwin
import Foundation

/// Runs the open-source LiveKit SFU binary bundled with the app (or `livekit-server` on PATH).
@MainActor
final class LocalLiveKitServer: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var wsURL: URL?
    @Published private(set) var lastError: String?

    private var process: Process?

    func startIfNeeded() async {
        guard !isRunning else { return }
        guard let executable = resolveExecutable() else {
            lastError = "Install livekit-server next to the app (see docs/LOCAL_CALLS.md) or add it to PATH."
            return
        }
        let process = Process()
        process.executableURL = executable
        process.arguments = ["--dev", "--bind", "0.0.0.0"]
        var env = ProcessInfo.processInfo.environment
        env["LIVEKIT_KEYS"] = "\(LocalCallConfiguration.liveKitAPIKey): \(LocalCallConfiguration.liveKitAPISecret)"
        process.environment = env
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            self.process = process
            isRunning = true
            let host = LocalNetworkAddress.lanHostIPv4() ?? "127.0.0.1"
            wsURL = URL(string: "ws://\(host):\(LocalCallConfiguration.liveKitHTTPPort)")
            lastError = nil
            try? await Task.sleep(nanoseconds: 800_000_000)
        } catch {
            lastError = error.localizedDescription
            isRunning = false
            wsURL = nil
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        isRunning = false
        wsURL = nil
    }

    private func resolveExecutable() -> URL? {
        if let bundle = Bundle.main.resourceURL {
            for name in LocalCallConfiguration.bundledLiveKitServerNames {
                let url = bundle.appendingPathComponent(name)
                if FileManager.default.isExecutableFile(atPath: url.path) {
                    return url
                }
            }
        }
        for name in LocalCallConfiguration.bundledLiveKitServerNames {
            let path = "/usr/local/bin/\(name)"
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}

enum LocalNetworkAddress {
    static func lanHostIPv4() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        var ptr = first
        while true {
            let interface = ptr.pointee
            let family = interface.ifa_addr.pointee.sa_family
            if family == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name.hasPrefix("en") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    let ip = String(cString: hostname)
                    if !ip.hasPrefix("127.") { return ip }
                }
            }
            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        return "127.0.0.1"
    }
}
