import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    var module: AppModule

    var body: some View {
        HStack(spacing: 16) {
            Button {
                if updates.canInstallNow {
                    Task { await updates.updateNow() }
                } else {
                    Task { await updates.checkForUpdates(silent: false) }
                }
            } label: {
                Text(updates.statusLine)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .help(updates.canInstallNow ? "Download and install update" : "Check for updates from GitHub")

            if module == .chat {
                HStack(spacing: 6) {
                    Image(systemName: chat.isOffline ? "wifi.slash" : "checkmark.circle.fill")
                        .font(.system(size: 10))
                    Text(chat.isOffline ? "Chat offline (cached)" : "Realtime chat")
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

            if let profile = auth.profile {
                Text(profile.email)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }

            Spacer()

            if updates.canInstallNow {
                Button("Update now") {
                    Task { await updates.updateNow() }
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.accent)
            }

            Text(module.label)
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.statusBarForeground.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .foregroundStyle(CursorTheme.statusBarForeground.opacity(0.95))
        .background(CursorTheme.statusBar)
    }
}
