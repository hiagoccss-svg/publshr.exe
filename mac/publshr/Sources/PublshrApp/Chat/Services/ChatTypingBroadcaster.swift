import Foundation
import Supabase

/// Realtime broadcast typing indicators per channel (Slack-style).
actor ChatTypingBroadcaster {
    private let client: SupabaseClient
    private let workspaceId: UUID
    private var channel: RealtimeChannelV2?
    private var listenTask: Task<Void, Never>?

    var onTyping: (@Sendable (UUID, String) -> Void)?
    var onStop: (@Sendable (UUID) -> Void)?

    init(client: SupabaseClient, workspaceId: UUID) {
        self.client = client
        self.workspaceId = workspaceId
    }

    func configureHandlers(
        onTyping: (@Sendable (UUID, String) -> Void)?,
        onStop: (@Sendable (UUID) -> Void)?
    ) {
        self.onTyping = onTyping
        self.onStop = onStop
    }

    func subscribe(channelId: UUID) async {
        listenTask?.cancel()
        let ch = await client.channel("chat-typing-\(workspaceId.uuidString)-\(channelId.uuidString)")
        channel = ch
        await ch.subscribe()
        listenTask = Task {
            for await event in ch.broadcastStream(event: "typing") {
                let data = event["payload"]?.objectValue ?? event
                guard let cidStr = data["channel_id"]?.stringValue,
                      let cid = UUID(uuidString: cidStr),
                      let name = data["display_name"]?.stringValue else { continue }
                if data["stop"]?.boolValue == true {
                    onStop?(cid)
                } else {
                    onTyping?(cid, name)
                }
            }
        }
    }

    func sendTyping(channelId: UUID, userId: UUID, displayName: String) async {
        guard let channel else { return }
        await channel.broadcast(
            event: "typing",
            message: [
                "channel_id": .string(channelId.uuidString),
                "user_id": .string(userId.uuidString),
                "display_name": .string(displayName),
            ]
        )
    }

    func stopTyping(channelId: UUID, userId: UUID, displayName: String) async {
        guard let channel else { return }
        await channel.broadcast(
            event: "typing",
            message: [
                "channel_id": .string(channelId.uuidString),
                "user_id": .string(userId.uuidString),
                "display_name": .string(displayName),
                "stop": .bool(true),
            ]
        )
    }

    func unsubscribe() async {
        listenTask?.cancel()
        if let channel { await channel.unsubscribe() }
        self.channel = nil
    }
}
