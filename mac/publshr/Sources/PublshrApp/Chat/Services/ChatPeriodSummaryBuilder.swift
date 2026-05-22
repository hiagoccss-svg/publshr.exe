import Foundation

/// Builds a detailed "script" recap of channel activity for a date range (local heuristics; LLM-ready later).
enum ChatPeriodSummaryBuilder {
    private static let scriptTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private static let scriptDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f
    }()

    private static let periodFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static func build(
        messages: [ChatMessage],
        profiles: [UUID: Profile],
        channelTitle: String,
        periodStart: Date,
        periodEnd: Date,
        truncated: Bool = false
    ) -> ChatAIResult {
        let start = Calendar.current.startOfDay(for: periodStart)
        let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: periodEnd) ?? periodEnd

        let inRange = messages
            .filter { !$0.isDeleted && $0.createdAt >= start && $0.createdAt <= end }
            .sorted { $0.createdAt < $1.createdAt }

        guard !inRange.isEmpty else {
            return ChatAIResult(
                title: "Period recap — \(channelTitle)",
                body: "No messages in this channel between \(periodFormatter.string(from: start)) and \(periodFormatter.string(from: end)). Try widening the date range or pick another channel.",
                actionItems: [],
                deadlines: []
            )
        }

        let participants = participantNames(inRange, profiles: profiles)
        let mainCount = inRange.filter { $0.threadParentId == nil }.count
        let threadCount = inRange.filter { $0.threadParentId != nil }.count

        var script = """
        # Chat script recap — \(channelTitle)

        **Period:** \(periodFormatter.string(from: start)) → \(periodFormatter.string(from: end))
        **Volume:** \(inRange.count) messages (\(mainCount) in channel, \(threadCount) in threads)
        **People:** \(participants.joined(separator: ", "))
        """

        if truncated {
            script += "\n**Note:** Showing the most recent \(inRange.count) messages in range (limit reached). Narrow dates for full detail."
        }

        script += "\n\n---\n\n## What happened (chronological script)\n"

        let byDay = Dictionary(grouping: inRange) { msg in
            Calendar.current.startOfDay(for: msg.createdAt)
        }
        let sortedDays = byDay.keys.sorted()

        for day in sortedDays {
            guard let dayMessages = byDay[day]?.sorted(by: { $0.createdAt < $1.createdAt }) else { continue }
            script += "\n### \(scriptDayFormatter.string(from: day))\n\n"
            for msg in dayMessages {
                script += formatScriptLine(msg, profiles: profiles, allMessages: inRange)
            }
        }

        let joined = inRange.compactMap(\.body).joined(separator: "\n")
        let highlights = extractHighlights(from: inRange, profiles: profiles)
        if !highlights.isEmpty {
            script += "\n---\n\n## Key moments\n"
            for line in highlights {
                script += "\n• \(line)"
            }
        }

        let actions = ChatAIService.extractActionItems(from: joined)
        let deadlines = extractDeadlines(from: joined)

        if !actions.isEmpty {
            script += "\n\n---\n\n## Follow-ups mentioned\n"
            for item in actions {
                script += "\n• \(item)"
            }
        }

        return ChatAIResult(
            title: "Script recap — \(channelTitle)",
            body: script.trimmingCharacters(in: .whitespacesAndNewlines),
            actionItems: actions,
            deadlines: deadlines
        )
    }

    private static func formatScriptLine(
        _ msg: ChatMessage,
        profiles: [UUID: Profile],
        allMessages: [ChatMessage]
    ) -> String {
        let name = profiles[msg.userId]?.displayName
            ?? profiles[msg.userId]?.email
            ?? "Member"
        let time = scriptTimeFormatter.string(from: msg.createdAt)
        let body = messageBodyText(msg)

        if let parentId = msg.threadParentId,
           let parent = allMessages.first(where: { $0.id == parentId }) {
            let parentName = profiles[parent.userId]?.displayName ?? "someone"
            let preview = (parent.body ?? "").prefix(60)
            return "  ↳ **\(time)** — **\(name)** (in thread with \(parentName): \"\(preview)\"): \(body)\n"
        }

        if body.isEmpty, !msg.attachments.isEmpty {
            let kinds = msg.attachments.map { $0.kindLabel }.joined(separator: ", ")
            return "• **\(time)** — **\(name)** shared \(kinds).\n"
        }

        return "• **\(time)** — **\(name):** \(body)\n"
    }

    private static func messageBodyText(_ msg: ChatMessage) -> String {
        let raw = (msg.body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty { return raw }
        if msg.isDeleted { return "[message removed]" }
        return ""
    }

    private static func participantNames(
        _ messages: [ChatMessage],
        profiles: [UUID: Profile]
    ) -> [String] {
        var seen = Set<UUID>()
        var names: [String] = []
        for msg in messages {
            guard seen.insert(msg.userId).inserted else { continue }
            let label = profiles[msg.userId]?.displayName
                ?? profiles[msg.userId]?.email
                ?? "Member"
            names.append(label)
        }
        return names
    }

    private static func extractHighlights(
        from messages: [ChatMessage],
        profiles: [UUID: Profile]
    ) -> [String] {
        let cues = ["decided", "approved", "blocked", "launch", "deadline", "urgent", "ship", "merged", "signed off"]
        var out: [String] = []
        for msg in messages where msg.threadParentId == nil {
            guard let body = msg.body, body.count > 20 else { continue }
            guard cues.contains(where: { body.localizedCaseInsensitiveContains($0) }) else { continue }
            let name = profiles[msg.userId]?.displayName ?? "Someone"
            let snippet = String(body.prefix(100))
            out.append("\(name) (\(scriptTimeFormatter.string(from: msg.createdAt))): \"\(snippet)\(body.count > 100 ? "…" : "")\"")
            if out.count >= 8 { break }
        }
        return out
    }

    private static func extractDeadlines(from text: String) -> [String] {
        let tokens = ["today", "tomorrow", "eod", "eow", "monday", "tuesday", "wednesday", "thursday", "friday", "due"]
        return tokens.compactMap { token in
            text.range(of: token, options: .caseInsensitive).map { _ in "Mentioned: \(token)" }
        }
    }
}

private extension ChatAttachment {
    var kindLabel: String {
        if isVoice { return "a voice note" }
        if isImage { return "an image" }
        if isVideo { return "a video" }
        return "a file"
    }
}
