import SwiftUI

/// Read-only status strip — live updates and Supabase sync run automatically.
struct StatusBarView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    var module: AppModule

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                if updates.isActivelyUpdating {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.65)
                }
                Text(updates.statusLine)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }

            if module == .chat {
                HStack(spacing: 6) {
                    Image(systemName: chat.isOffline ? "wifi.slash" : "checkmark.circle.fill")
                        .font(.system(size: 10))
                    Text(chat.isOffline ? "Offline" : chat.isLoading ? "Syncing…" : "Connected")
                        .font(.system(size: 11))
                }

                if chat.totalUnread > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 10))
                        Text("\(chat.totalUnread) unread")
                            .font(.system(size: 11))
                    }
                }
            }

            if module == .spaces {
                HStack(spacing: 6) {
                    Image(systemName: spacesStatusIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(spaces.isOffline ? CursorTheme.error : CursorTheme.success)
                    Text(spacesStatusLine)
                        .font(.system(size: 11))
                }
                if let synced = spaces.lastSyncedAt, !spaces.isOffline {
                    Text("Updated \(synced, style: .relative) ago")
                        .font(.system(size: 10))
                        .foregroundStyle(CursorTheme.statusBarForeground.opacity(0.7))
                }
            }

            if let profile = auth.profile {
                Text(profile.email)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.statusBarForeground.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer()

            Text(module.label)
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.statusBarForeground.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .foregroundStyle(CursorTheme.statusBarForeground.opacity(0.95))
        .background(CursorTheme.statusBar)
    }

    private var spacesStatusIcon: String {
        if spaces.isOffline { return "wifi.slash" }
        if spaces.isLoading { return "arrow.triangle.2.circlepath" }
        return "circle.fill"
    }

    private var spacesStatusLine: String {
        if spaces.isOffline { return "Offline — showing cached data" }
        if spaces.isLoading { return "Syncing spaces…" }
        return "Spaces live"
    }
}
