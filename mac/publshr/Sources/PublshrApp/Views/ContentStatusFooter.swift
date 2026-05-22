import SwiftUI

/// Thin status line under the main content column only (sidebars run full height).
struct ContentStatusFooter: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    var module: AppModule

    var body: some View {
        HStack(spacing: 12) {
            if updates.isActivelyUpdating {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.55)
            }
            Text(updates.statusLine)
                .font(.system(size: 10))
                .foregroundStyle(CursorTheme.foregroundDim)
                .lineLimit(1)

            if module == .chat {
                Text(chat.isOffline ? "Offline" : chat.isLoading ? "Syncing" : "Connected")
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
                if chat.totalUnread > 0 {
                    Text("\(chat.totalUnread) unread")
                        .font(.system(size: 10))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
            }

            if module == .spaces, spaces.isLoading {
                Text("Syncing")
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }

            Spacer()

            if let profile = auth.profile {
                Text(profile.email)
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .foregroundStyle(CursorTheme.foregroundDim)
        .background(footerBackground)
        .overlay(alignment: .top) {
            if module != .chat {
                Rectangle()
                    .fill(CursorTheme.border.opacity(0.25))
                    .frame(height: 1)
            }
        }
    }

    private var footerBackground: Color {
        Color.clear
    }
}
