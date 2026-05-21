import Foundation

/// Phase 4 AI helpers — local heuristics today; swap for AI Gateway / SDK later.
enum ChatAIService {
    static func summarizeMessages(_ messages: [ChatMessage], profiles: [UUID: Profile]) -> ChatAIResult {
        let recent = messages.filter { !$0.isDeleted }.suffix(40)
        let lines = recent.map { msg -> String in
            let name = profiles[msg.userId]?.displayName ?? "Member"
            return "\(name): \(msg.body ?? "")"
        }
        let joined = lines.joined(separator: "\n")
        let bullets = extractBullets(from: joined, max: 5)
        let actions = extractActionItems(from: joined)
        let deadlines = extractDeadlines(from: joined)
        return ChatAIResult(
            title: "Conversation summary",
            body: bullets.isEmpty ? "No substantive messages to summarize yet." : bullets.map { "• \($0)" }.joined(separator: "\n"),
            actionItems: actions,
            deadlines: deadlines
        )
    }

    static func summarizeThread(root: ChatMessage, replies: [ChatMessage], profiles: [UUID: Profile]) -> ChatAIResult {
        var all = [root] + replies
        return summarizeMessages(all, profiles: profiles)
    }

    static func suggestReply(to messages: [ChatMessage]) -> String {
        guard let last = messages.last(where: { !$0.isDeleted }), let body = last.body, !body.isEmpty else {
            return "Thanks — I'll take a look and follow up shortly."
        }
        if body.localizedCaseInsensitiveContains("?") {
            return "Good question — I'll confirm and get back to you."
        }
        if body.localizedCaseInsensitiveContains("approve") {
            return "Reviewing now. I'll share an update once it's ready."
        }
        return "Acknowledged — thanks for the update."
    }

    static func extractActionItems(from text: String) -> [String] {
        let patterns = ["need to", "please", "can you", "todo", "action:", "follow up", "by friday", "by monday", "asap"]
        return text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { line in patterns.contains { line.localizedCaseInsensitiveContains($0) } }
            .prefix(6)
            .map { String($0.prefix(120)) }
    }

    static func mockTranscribeVoice(durationMs: Int) -> String {
        let seconds = durationMs / 1000
        return "Voice note (\(seconds)s) — transcription will appear here when the speech service is connected."
    }

    private static func extractBullets(from text: String, max: Int) -> [String] {
        let sentences = text
            .components(separatedBy: CharacterSet(charactersIn: ".!\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 12 }
        return Array(sentences.suffix(max))
    }

    private static func extractDeadlines(from text: String) -> [String] {
        let tokens = ["today", "tomorrow", "eod", "eow", "monday", "tuesday", "wednesday", "thursday", "friday", "due"]
        return tokens.compactMap { token in
            text.range(of: token, options: .caseInsensitive).map { _ in "Mentioned: \(token)" }
        }
    }
}
