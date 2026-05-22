import SwiftUI

/// Borderless chat chrome — integrated with the conversation (native desktop, not web cards).
struct ChatWorkspaceChrome<Content: View>: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var calls: CallSignalingService
    @ObservedObject var chat: ChatViewModel
    var topInset: CGFloat = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)
            chromeBar
            content()
        }
        .background(CursorTheme.chatBackground)
    }

    private var chromeBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                chromeNavButton("chevron.left", enabled: chat.canNavigateBack) { chat.navigateBack() }
                chromeNavButton("chevron.right", enabled: chat.canNavigateForward) { chat.navigateForward() }
            }

            if let channel = chat.selectedChannel {
                VStack(alignment: .leading, spacing: 0) {
                    Text(channel.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                        .lineLimit(1)
                    Text(channelSubtitle(channel))
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .lineLimit(1)
                }
            } else {
                Text("Chat")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                TextField("Search", text: $chat.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(maxWidth: 200)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)

            HStack(spacing: 14) {
                if chat.selectedChannel != nil, subscription.canUseCalls(workspace: auth.selectedWorkspace) {
                    callMenu
                }
                if chat.selectedChannel != nil {
                    chromeAction(chat.showPinnedPanel ? "pin.fill" : "pin") {
                        chat.showPinnedPanel.toggle()
                    }
                }
                chromeAction(chat.chatFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") {
                    withAnimation(.easeInOut(duration: 0.18)) { chat.chatFocusMode.toggle() }
                }
                chromeAction("sparkles") { chat.showAISheet = true }
                chromeAction("gearshape") { chat.showPermissionsSheet = true }
                presenceMenu
            }

            if !auth.workspaceMemberships.isEmpty {
                workspaceMenu
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .padding(.bottom, 4)
        .frame(height: CursorTheme.chatToolbarHeight)
    }

    private func channelSubtitle(_ channel: ChatChannel) -> String {
        if let desc = channel.description, !desc.isEmpty { return desc }
        let n = chat.channelMemberCount(for: channel)
        return n == 1 ? "1 member" : "\(n) members"
    }

    private func chromeNavButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(enabled ? CursorTheme.foregroundMuted : CursorTheme.foregroundDim.opacity(0.35))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func chromeAction(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .buttonStyle(.plain)
    }

    private var presenceMenu: some View {
        Menu {
            ForEach(ChatPresenceStatus.allCases.filter { $0 != .invisible }, id: \.self) { status in
                Button { Task { await chat.setStatus(status) } } label: {
                    Label(status.label, systemImage: status == chat.myStatus ? "checkmark" : "circle.fill")
                }
            }
        } label: {
            ChatPresenceDot(status: chat.myStatus, size: 8)
        }
        .menuStyle(.borderlessButton)
    }

    private var callMenu: some View {
        Menu {
            Button { startCall(video: false) } label: {
                Label("Voice call", systemImage: "phone.fill")
            }
            Button { startCall(video: true) } label: {
                Label("Video call", systemImage: "video.fill")
            }
        } label: {
            Image(systemName: "phone")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .menuStyle(.borderlessButton)
        .help("Start a call")
    }

    private func startCall(video: Bool) {
        guard let ws = auth.selectedWorkspace?.id,
              let channel = chat.selectedChannel else { return }
        Task {
            await calls.startChannelCall(
                workspaceId: ws,
                channelId: channel.id,
                title: channel.displayTitle,
                video: video,
                workspaceSettings: auth.selectedWorkspace?.settings
            )
        }
    }

    private var workspaceMenu: some View {
        Menu {
            ForEach(auth.workspaceMemberships) { m in
                Button { auth.switchWorkspace(m) } label: {
                    Text("\(m.workspace.name) · \(m.role.label)")
                }
            }
        } label: {
            Text(auth.selectedMembership?.workspace.name ?? "Workspace")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundDim)
                .lineLimit(1)
        }
        .menuStyle(.borderlessButton)
    }
}
