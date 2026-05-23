import Foundation

/// Human-readable presence and last-seen labels for enterprise chat (local timezone).
enum ChatPresenceFormatter {
    static var useLocalTimeZone: Bool {
        ChatUserPreferences.showTimestampsInLocalTimeZone
    }

    static func statusLine(for record: ChatPresence?, status: ChatPresenceStatus) -> String {
        guard let record else { return status.label }
        switch status {
        case .online:
            if let activity = record.activity?.trimmingCharacters(in: .whitespacesAndNewlines), !activity.isEmpty {
                return activity
            }
            return "Active now"
        case .away, .busy, .inMeeting:
            return "\(status.label) · \(lastSeenPhrase(record.lastSeenAt))"
        case .offline, .invisible:
            return lastSeenPhrase(record.lastSeenAt)
        }
    }

    static func lastSeenPhrase(_ date: Date) -> String {
        let now = Date()
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "Last seen just now" }
        if seconds < 3600 {
            let m = Int(seconds / 60)
            return "Last seen \(m)m ago"
        }
        if seconds < 86_400 {
            let h = Int(seconds / 3600)
            return "Last seen \(h)h ago"
        }
        return "Last seen \(formatAbsolute(date))"
    }

    static func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = useLocalTimeZone ? .current : TimeZone(identifier: "UTC")
        let tz = formatter.timeZone?.abbreviation() ?? "UTC"
        return "\(formatter.string(from: date)) \(tz)"
    }

    static func formatAbsolute(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = useLocalTimeZone ? .current : TimeZone(identifier: "UTC")
        let tz = formatter.timeZone?.abbreviation() ?? "UTC"
        return "\(formatter.string(from: date)) (\(tz))"
    }
}
