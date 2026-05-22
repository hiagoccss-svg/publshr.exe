import Supabase
import SwiftUI

/// Workspace member avatar — Supabase storage path or legacy URL, with signed URL loading.
struct ChatProfileAvatar: View {
    @EnvironmentObject private var auth: AuthViewModel

    let profile: Profile?
    let displayName: String
    var size: CGFloat = 32
    var presence: ChatPresenceStatus?

    @State private var resolvedImageURL: URL?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
            if let presence, presence != .invisible {
                ChatPresenceDot(status: presence, size: max(8, size * 0.28))
                    .offset(x: 1, y: 1)
            }
        }
        .task(id: avatarTaskKey) {
            resolvedImageURL = nil
            let supabase = auth.session != nil ? auth.client : nil
            resolvedImageURL = await ProfileService.resolveAvatarURL(
                client: supabase,
                avatarUrl: profile?.avatarUrl
            )
        }
    }

    private var avatarTaskKey: String {
        "\(profile?.id.uuidString ?? "none")|\(profile?.avatarUrl ?? "")|\(auth.avatarDisplayToken.uuidString)"
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let url = resolvedImageURL {
            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
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
            .id(avatarTaskKey)
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
