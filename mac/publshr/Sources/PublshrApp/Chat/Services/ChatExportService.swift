import Foundation

enum ChatExportService {
    static func suggestedFilename(channel: ChatChannel) -> String {
        let base = channel.sidebarTitle
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let stamp = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return "\(base)-chat-\(stamp).txt"
    }

    static func buildTranscript(
        channel: ChatChannel,
        messages: [ChatMessage],
        displayName: (UUID) -> String
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        var lines: [String] = [
            "Chat export — \(channel.displayTitle)",
            "Exported \(formatter.string(from: Date()))",
            "",
        ]
        let sorted = messages.sorted { $0.createdAt < $1.createdAt }
        for msg in sorted where msg.threadParentId == nil {
            if msg.isDeleted {
                lines.append("[\(formatter.string(from: msg.createdAt))] \(displayName(msg.userId)): (deleted)")
                continue
            }
            let body = msg.body ?? attachmentLabel(msg)
            lines.append("[\(formatter.string(from: msg.createdAt))] \(displayName(msg.userId)): \(body)")
        }
        return lines.joined(separator: "\n")
    }

    private static func attachmentLabel(_ message: ChatMessage) -> String {
        if message.attachments.contains(where: \.isVoice) { return "[voice note]" }
        if message.attachments.contains(where: \.isImage) { return "[image]" }
        if message.attachments.contains(where: \.isVideo) { return "[video]" }
        if !message.attachments.isEmpty { return "[attachment]" }
        return ""
    }
}
