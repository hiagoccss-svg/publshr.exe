import Foundation
import Network

/// LAN signaling for call presence (mute/video/join/leave). Media stays on the embedded SFU.
@MainActor
final class LocalCallSignalingHub: ObservableObject {
    struct Participant: Identifiable, Equatable, Codable {
        let userId: UUID
        var displayName: String
        var isMuted: Bool
        var isVideoEnabled: Bool
        var joinedAt: Date

        var id: UUID { userId }
    }

    @Published private(set) var participants: [Participant] = []
    @Published private(set) var isHosting = false
    @Published private(set) var hostAddress: String?
    @Published private(set) var signalingPort: UInt16?
    @Published private(set) var roomCode: String?

    private var listener: NWListener?
    private var connections: [UUID: NWConnection] = [:]
    private var netService: NetService?
    private var browser: NetServiceBrowser?
    private var discoveredService: NetService?
    private var roomId: UUID?
    private var channelId: UUID?
    private var localUserId: UUID?
    private var localDisplayName = "You"

    func startHosting(roomId: UUID, channelId: UUID, roomCode: String, displayName: String, userId: UUID) async throws {
        stop()
        self.roomId = roomId
        self.channelId = channelId
        self.roomCode = roomCode
        self.localUserId = userId
        self.localDisplayName = displayName
        isHosting = true

        let listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: LocalCallConfiguration.signalingPort)!)
        listener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                self?.accept(connection: connection)
            }
        }
        listener.stateUpdateHandler = { state in
            if case .failed(let err) = state {
                NSLog("LocalCall signaling listener failed: \(err)")
            }
        }
        listener.start(queue: .main)
        self.listener = listener
        signalingPort = LocalCallConfiguration.signalingPort
        hostAddress = LocalNetworkAddress.lanHostIPv4() ?? "127.0.0.1"

        upsertLocalParticipant()
        publishBonjour(roomCode: roomCode, channelId: channelId)
    }

    func joinRemote(host: String, port: UInt16, roomId: UUID, channelId: UUID, displayName: String, userId: UUID) async {
        stop()
        self.roomId = roomId
        self.channelId = channelId
        self.localUserId = userId
        self.localDisplayName = displayName
        isHosting = false
        hostAddress = host
        signalingPort = port

        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: .tcp
        )
        let connId = UUID()
        connections[connId] = connection
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                Task { @MainActor in
                    self?.sendJoin(on: connection)
                }
            }
        }
        connection.start(queue: .main)
        receive(on: connection)
    }

    func browseAndJoin(channelId: UUID, roomId: UUID, displayName: String, userId: UUID) {
        stop()
        self.channelId = channelId
        self.roomId = roomId
        self.localUserId = userId
        self.localDisplayName = displayName
        let browser = NetServiceBrowser()
        browser.delegate = BonjourBrowserDelegate { [weak self] service in
            Task { @MainActor in
                await self?.resolveAndJoin(service: service, channelId: channelId, roomId: roomId)
            }
        }
        browser.searchForServices(ofType: LocalCallConfiguration.bonjourType, inDomain: LocalCallConfiguration.bonjourDomain)
        self.browser = browser
    }

    func updateLocalMediaState(isMuted: Bool, isVideoEnabled: Bool) {
        guard let userId = localUserId else { return }
        if let idx = participants.firstIndex(where: { $0.userId == userId }) {
            participants[idx].isMuted = isMuted
            participants[idx].isVideoEnabled = isVideoEnabled
        }
        broadcastState()
    }

    func stop() {
        listener?.cancel()
        listener = nil
        for (_, connection) in connections {
            connection.cancel()
        }
        connections = []
        netService?.stop()
        netService = nil
        browser?.stop()
        browser = nil
        discoveredService?.stop()
        discoveredService = nil
        participants = []
        isHosting = false
        hostAddress = nil
        signalingPort = nil
        roomCode = nil
    }

    private func accept(connection: NWConnection) {
        let id = UUID()
        connections[id] = connection
        connection.start(queue: .main)
        receive(on: connection)
        sendSnapshot(to: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, _, _ in
            guard let self, let data, !data.isEmpty else { return }
            Task { @MainActor in
                self.handleIncoming(data: data)
                self.receive(on: connection)
            }
        }
    }

    private func handleIncoming(data: Data) {
        guard let line = String(data: data, encoding: .utf8)?
            .split(separator: "\n", omittingEmptySubsequences: true)
            .last,
              let jsonData = line.data(using: .utf8),
              let envelope = try? JSONDecoder().decode(SignalingEnvelope.self, from: jsonData)
        else { return }

        switch envelope.type {
        case "join":
            if let p = envelope.participant {
                if participants.count >= LocalCallConfiguration.maxParticipants,
                   !participants.contains(where: { $0.userId == p.userId }) {
                    return
                }
                participants.removeAll { $0.userId == p.userId }
                participants.append(p)
                participants.sort { $0.joinedAt < $1.joinedAt }
                if isHosting { broadcastState() }
            }
        case "leave":
            if let uid = envelope.userId {
                participants.removeAll { $0.userId == uid }
                if isHosting { broadcastState() }
            }
        case "state":
            if let list = envelope.participants {
                participants = list
            }
        default:
            break
        }
    }

    private func upsertLocalParticipant() {
        guard let userId = localUserId else { return }
        let p = Participant(
            userId: userId,
            displayName: localDisplayName,
            isMuted: false,
            isVideoEnabled: false,
            joinedAt: Date()
        )
        participants.removeAll { $0.userId == userId }
        participants.append(p)
    }

    private func sendJoin(on connection: NWConnection) {
        guard let userId = localUserId else { return }
        let p = Participant(
            userId: userId,
            displayName: localDisplayName,
            isMuted: false,
            isVideoEnabled: false,
            joinedAt: Date()
        )
        send(envelope: SignalingEnvelope(type: "join", participant: p, userId: nil, participants: nil), to: connection)
    }

    private func broadcastState() {
        let envelope = SignalingEnvelope(type: "state", participant: nil, userId: nil, participants: participants)
        for (_, connection) in connections {
            send(envelope: envelope, to: connection)
        }
    }

    private func sendSnapshot(to connection: NWConnection) {
        let envelope = SignalingEnvelope(type: "state", participant: nil, userId: nil, participants: participants)
        send(envelope: envelope, to: connection)
    }

    private func send(envelope: SignalingEnvelope, to connection: NWConnection) {
        guard var data = try? JSONEncoder().encode(envelope) else { return }
        data.append(0x0A)
        connection.send(content: data, completion: .contentProcessed { _ in })
    }

    private func publishBonjour(roomCode: String, channelId: UUID) {
        guard let port = signalingPort else { return }
        let service = NetService(
            domain: LocalCallConfiguration.bonjourDomain,
            type: LocalCallConfiguration.bonjourType,
            name: "call-\(roomCode)",
            port: Int32(port)
        )
        service.delegate = BonjourPublishDelegate()
        var txt: [String: Data] = [
            "room": roomCode.data(using: .utf8) ?? Data(),
            "channel": channelId.uuidString.data(using: .utf8) ?? Data(),
        ]
        if let host = hostAddress?.data(using: .utf8) {
            txt["host"] = host
        }
        service.setTXTRecord(NetService.data(fromTXTRecord: txt))
        service.publish()
        netService = service
    }

    private func resolveAndJoin(service: NetService, channelId: UUID, roomId: UUID) async {
        guard let txt = service.txtRecordData(),
              let dict = NetService.dictionary(fromTXTRecord: txt) as? [String: Data],
              let channelRaw = dict["channel"].flatMap({ String(data: $0, encoding: .utf8) }),
              channelRaw == channelId.uuidString
        else { return }
        service.resolve(withTimeout: 5)
        discoveredService = service
        let host = service.hostName ?? dict["host"].flatMap { String(data: $0, encoding: .utf8) } ?? "127.0.0.1"
        let port = UInt16(service.port)
        await joinRemote(host: host, port: port > 0 ? port : LocalCallConfiguration.signalingPort, roomId: roomId, channelId: channelId, displayName: localDisplayName, userId: localUserId ?? UUID())
    }
}

private struct SignalingEnvelope: Codable {
    let type: String
    let participant: LocalCallSignalingHub.Participant?
    let userId: UUID?
    let participants: [LocalCallSignalingHub.Participant]?
}

private final class BonjourPublishDelegate: NSObject, NetServiceDelegate {}

private final class BonjourBrowserDelegate: NSObject, NetServiceBrowserDelegate {
    private let onFound: (NetService) -> Void
    init(onFound: @escaping (NetService) -> Void) { self.onFound = onFound }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        onFound(service)
    }
}
