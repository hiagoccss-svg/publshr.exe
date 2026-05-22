import SwiftUI

/// Enterprise team chat — Phases 1–4 integrated.
struct EnterpriseChatView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var chat: ChatViewModel
    @State private var showNewChannel = false
    @State private var showNewDM = false
    @State private var showPlannerShare = false
    @State private var newChannelName = ""

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
        .sheet(isPresented: $chat.showSearchSheet) { ChatSearchSheet(chat: chat) }
        .sheet(isPresented: $chat.showAISheet) { ChatAISheet(chat: chat) }
        .sheet(isPresented: $chat.showPermissionsSheet) { ChatPermissionsSheet(chat: chat) }
        .sheet(isPresented: $showPlannerShare) { plannerShareSheet }
        .onAppear {
            if chat.currentUserId == nil {
                chat.attach(auth: auth)
            }
        }
    }

    private var chatToolbar: some View {
        HStack(spacing: 8) {
            Text(chat.workspace?.name ?? "Workspace")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
                .lineLimit(1)

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

            toolbarIcon("magnifyingglass") { chat.showSearchSheet = true }
            toolbarIcon("sparkles") { chat.showAISheet = true }
            toolbarIcon("checklist") {
                Task { await chat.loadPlannerTasks() }
                showPlannerShare = true
            }
            toolbarIcon("rectangle.portrait.on.rectangle.portrait") {
                chat.popOutCurrentChannel(auth: auth)
            }
            toolbarIcon("gearshape") { chat.showPermissionsSheet = true }
            statusMenu
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(CursorTheme.panelBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }

    private func toolbarIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .buttonStyle(.plain)
        .help(systemName)
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
            HStack(spacing: 4) {
                ChatPresenceDot(status: chat.myStatus, size: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
        }
        .menuStyle(.borderlessButton)
    }

    private var newChannelSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Channel").font(.headline)
            TextField("Channel name", text: $newChannelName)
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
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    private var newDMSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Message").font(.headline)
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
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(minHeight: 200)
            Button("Close") { showNewDM = false }
        }
        .padding(20)
        .frame(width: 320, height: 360)
    }

    private var plannerShareSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share planner item").font(.headline)
            if chat.plannerTasks.isEmpty {
                Text("No tasks in workspace yet.")
                    .foregroundStyle(.secondary)
            } else {
                List(chat.plannerTasks) { task in
                    Button {
                        Task {
                            await chat.sharePlannerTask(task)
                            showPlannerShare = false
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(task.title)
                            Text(task.status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Button("Close") { showPlannerShare = false }
        }
        .padding(20)
        .frame(width: 360, height: 400)
    }
}
