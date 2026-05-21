import SwiftUI

/// Enterprise team chat panel — channels, DMs, realtime, presence, local cache.
struct EnterpriseChatView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var chat: ChatViewModel
    @State private var showNewChannel = false
    @State private var showNewDM = false
    @State private var newChannelName = ""
    @State private var showStatusMenu = false

    var body: some View {
        HStack(spacing: 0) {
            ChatSidebarView(
                chat: chat,
                showNewChannel: $showNewChannel,
                showNewDM: $showNewDM
            )

            VStack(spacing: 0) {
                chatToolbar
                ChatConversationView(chat: chat)
            }
        }
        .background(CursorTheme.panelBackground)
        .sheet(isPresented: $showNewChannel) { newChannelSheet }
        .sheet(isPresented: $showNewDM) { newDMSheet }
        .onAppear {
            if chat.currentUserId == nil {
                chat.attach(auth: auth)
            }
        }
    }

    private var chatToolbar: some View {
        HStack(spacing: 12) {
            Text(workspaceTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            if chat.totalUnread > 0 {
                Text("\(chat.totalUnread)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(CursorTheme.accent)
                    .clipShape(Capsule())
            }
            Spacer()
            statusMenu
            if let err = chat.errorMessage {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.error)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CursorTheme.panelBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }

    private var workspaceTitle: String {
        chat.workspace?.name ?? "Workspace"
    }

    private var statusMenu: some View {
        Menu {
            ForEach(ChatPresenceStatus.allCases.filter { $0 != .invisible }, id: \.self) { status in
                Button {
                    Task { await chat.setStatus(status) }
                } label: {
                    Label(status.label, systemImage: status == chat.myStatus ? "checkmark" : "circle.fill")
                }
            }
        } label: {
            HStack(spacing: 6) {
                ChatPresenceDot(status: chat.myStatus, size: 8)
                Text(chat.myStatus.label)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
        }
        .menuStyle(.borderlessButton)
    }

    private var newChannelSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Channel")
                .font(.headline)
            TextField("Channel name (e.g. editorial)", text: $newChannelName)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { showNewChannel = false }
                Button("Create") {
                    Task {
                        await chat.createChannel(name: newChannelName)
                        showNewChannel = false
                        newChannelName = ""
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    private var newDMSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Message")
                .font(.headline)
            Text("Select a teammate")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            List(Array(chat.profiles.values).sorted { ($0.displayName ?? $0.email) < ($1.displayName ?? $1.email) }) { profile in
                if profile.id != chat.currentUserId {
                    Button {
                        Task {
                            await chat.openDM(with: profile)
                            showNewDM = false
                        }
                    } label: {
                        HStack {
                            ChatPresenceDot(status: chat.presence(for: profile.id))
                            Text(profile.displayName ?? profile.email)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(minHeight: 200)
            Button("Close") { showNewDM = false }
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(width: 320, height: 360)
    }
}
