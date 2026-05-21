import Foundation

enum ChatMentionParser {
    static func parse(_ text: String, profiles: [UUID: Profile]) -> [ChatMentionToken] {
        var tokens: [ChatMentionToken] = []
        let pattern = #"@([\w\.\-]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return tokens }
        let range = NSRange(text.startIndex..., in: text)
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match, match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: text) else { return }
            let handle = String(text[r]).lowercased()
            if handle == "here" || handle == "channel" {
                tokens.append(ChatMentionToken(type: handle == "here" ? .here : .channel, raw: "@\(handle)", userId: nil))
                return
            }
            if let profile = profiles.values.first(where: {
                ($0.displayName ?? "").lowercased().replacingOccurrences(of: " ", with: "") == handle
                    || $0.email.lowercased().hasPrefix(handle)
            }) {
                tokens.append(ChatMentionToken(type: .user, raw: "@\(handle)", userId: profile.id))
            }
        }
        return tokens
    }

    static func highlightRanges(in text: String) -> [(Range<String.Index>, Bool)] {
        var result: [(Range<String.Index>, Bool)] = []
        let pattern = #"@[\w\.\-]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(text.startIndex..., in: text)
        regex.enumerateMatches(in: text, range: nsRange) { match, _, _ in
            guard let match, let range = Range(match.range, in: text) else { return }
            result.append((range, true))
        }
        return result
    }
}
