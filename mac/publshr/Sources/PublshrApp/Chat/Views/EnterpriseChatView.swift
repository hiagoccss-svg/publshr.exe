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
        .sheet(item: $chat.renameChannelTarget) { channel in
            ChatChannelRenameSheet(chat: chat, channel: channel)
        }
        .sheet(item: $chat.linkTaskForMessage) { message in
            ChatLinkTaskSheet(chat: chat, message: message)
        }
        .sheet(item: $chat.createTaskFromMessage) { message in
            ChatCreateTaskSheet(chat: chat, message: message)
        }
        .overlay(alignment: .top) {
            if let tip = chat.lastCopiedFeedback {
                Text(tip)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.75)))
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: chat.lastCopiedFeedback)
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
