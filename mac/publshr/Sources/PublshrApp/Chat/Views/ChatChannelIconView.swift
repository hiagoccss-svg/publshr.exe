import SwiftUI

/// ClickUp-style channel icon — colored initial for channels, SF Symbol for DMs/groups.
struct ChatChannelIconView: View {
    let channel: ChatChannel
    var size: CGFloat = 16

    var body: some View {
        switch channel.kind {
        case .channel, .thread:
            channelBadge
        case .dm, .group:
            Image(systemName: channel.sidebarIcon)
                .font(.system(size: size * 0.65, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .frame(width: size, height: size)
        }
    }

    private var channelBadge: some View {
        Text(channel.channelInitial)
            .font(.system(size: size * 0.55, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(channel.channelAccentColor)
            )
    }
}

extension ChatChannel {
    var channelInitial: String {
        let raw = name.hasPrefix("#") ? String(name.dropFirst()) : name
        let base = raw.split(separator: "-").first.map(String.init) ?? raw
        return String(base.prefix(1)).uppercased()
    }

    var channelAccentColor: Color {
        let hash = abs(name.hashValue)
        let hues: [Color] = [
            Color(red: 0.35, green: 0.55, blue: 0.95),
            Color(red: 0.55, green: 0.38, blue: 0.92),
            Color(red: 0.92, green: 0.45, blue: 0.38),
            Color(red: 0.28, green: 0.72, blue: 0.55),
            Color(red: 0.95, green: 0.62, blue: 0.22),
        ]
        return hues[hash % hues.count]
    }

    /// Sidebar label without leading `#` (icon/badge carries channel identity).
    var sidebarTitle: String {
        if kind == .dm {
            if let desc = description?.replacingOccurrences(of: "Direct message with ", with: ""), !desc.isEmpty {
                return desc
            }
            if name.hasPrefix("dm:") {
                return String(name.dropFirst(3))
            }
        }
        if kind == .group {
            if let desc = description, desc.hasPrefix("Group: ") {
                return String(desc.dropFirst(7))
            }
        }
        if kind == .channel {
            var n = name
            if n.hasPrefix("#") { n.removeFirst() }
            return n
        }
        return name
    }
}
