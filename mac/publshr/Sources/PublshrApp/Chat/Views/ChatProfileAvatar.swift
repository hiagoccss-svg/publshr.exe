import SwiftUI

/// Workspace member avatar — Supabase `avatar_url` when set, otherwise initials + presence ring.
struct ChatProfileAvatar: View {
    let profile: Profile?
    let displayName: String
    var size: CGFloat = 32
    var presence: ChatPresenceStatus?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
            if let presence, presence != .offline {
                ChatPresenceDot(status: presence, size: max(8, size * 0.28))
                    .offset(x: 1, y: 1)
            }
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let urlString = profile?.avatarUrl,
           let url = URL(string: urlString),
           !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    initialsView
                @unknown default:
                    initialsView
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(avatarColor.opacity(0.18))
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(avatarColor)
        }
        .frame(width: size, height: size)
    }

    private var initials: String {
        let parts = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
        if parts.isEmpty {
            return String(displayName.prefix(1)).uppercased()
        }
        return parts.joined().uppercased()
    }

    private var avatarColor: Color {
        let hash = displayName.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let hues: [Color] = [
            Color(hex: 0x6B4FBB),
            Color(hex: 0x0078D4),
            Color(hex: 0xC72E2E),
            Color(hex: 0x22863A),
            Color(hex: 0xD97706),
            Color(hex: 0x0891B2)
        ]
        return hues[abs(hash) % hues.count]
    }
}
