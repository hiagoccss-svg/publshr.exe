import SwiftUI

/// Enterprise team chat — main content column only (nav lives in AppSecondarySidebar).
struct EnterpriseChatView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var chat: ChatViewModel
    @State private var showPlannerShare = false

    var body: some View {
        VStack(spacing: 0) {
            chatToolbar
            ChatConversationView(chat: chat)
        }
        .background(CursorTheme.chatBackground)
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
            if let channel = chat.selectedChannel {
                Text(channel.displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CursorTheme.foreground)
                    .lineLimit(1)
            } else {
                Text("Select a channel")
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }

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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CursorTheme.titleBar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
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
