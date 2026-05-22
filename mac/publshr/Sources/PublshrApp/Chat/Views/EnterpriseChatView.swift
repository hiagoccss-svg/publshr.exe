import SwiftUI

/// Enterprise team chat — borderless column wired to the shell sidebars.
struct EnterpriseChatView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var chat: ChatViewModel
    var topInset: CGFloat = 0
    var embedInPopOut: Bool = false

    var body: some View {
        ChatWorkspaceChrome(topInset: topInset, embedInPopOut: embedInPopOut) {
            VStack(spacing: 0) {
                chatStatusBanner
                if !embedInPopOut, chat.selectedChannel != nil {
                    ChatChannelStatusBar(chat: chat)
                }
                ChatConversationView(chat: chat)
            }
        }
        .sheet(isPresented: $chat.showSearchSheet) { ChatSearchSheet(chat: chat) }
        .sheet(isPresented: $chat.showPermissionsSheet) { ChatPermissionsSheet(chat: chat) }
        .onAppear {
            if chat.currentUserId == nil {
                chat.attach(auth: auth)
            }
        }
    }

    @ViewBuilder
    private var chatStatusBanner: some View {
        if chat.isOffline {
            ModuleStatusBanner(
                text: chat.errorMessage ?? "Offline — showing cached channels. Check network or Supabase.",
                style: .warning
            )
        } else if let message = chat.errorMessage, !message.isEmpty {
            ModuleStatusBanner(text: message, style: .error)
        }
    }
}
