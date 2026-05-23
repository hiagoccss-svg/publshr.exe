import SwiftUI

/// Unified toolbar in the main content column only (Cursor Mac — not a full-window top bar).
struct ContentToolbarView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @ObservedObject var spaces: SpacesViewModel
    var module: AppModule

    private var toolbarHeight: CGFloat {
        switch module {
        case .chat, .spaces, .whiteboard, .mediaMonitoring: return CursorTheme.chatToolbarHeight
        case .settings: return CursorTheme.titleBarHeight
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            toolbarLeading
                .frame(minWidth: (module == .chat || module.usesSpacesSubmenu) ? 180 : 0, alignment: .leading)

            if module == .chat || module.usesSpacesSubmenu {
                searchField
                    .frame(maxWidth: .infinity)
            } else {
                searchField
                    .frame(maxWidth: 360)
                Spacer(minLength: 8)
            }

            toolbarTrailing
        }
        .padding(.leading, (module == .chat || module == .spaces) ? 14 : 12)
        .padding(.trailing, 14)
        .frame(height: toolbarHeight)
        .background(CursorTheme.editorBackground)
        .overlay(alignment: .bottom) {
            if module == .settings {
                Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
            }
        }
    }

    @ViewBuilder
    private var toolbarLeading: some View {
        switch module {
        case .chat:
            chatToolbarLeading
        case .spaces, .whiteboard:
            spacesToolbarLeading
        case .mediaMonitoring:
            Text("Media Monitoring")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
        case .settings:
            Text("Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
        }
    }

    @ViewBuilder
    private var chatToolbarLeading: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                navButton(
                    systemName: "chevron.left",
                    enabled: chat.canNavigateBack,
                    help: "Back"
                ) { chat.navigateBack() }
                navButton(
                    systemName: "chevron.right",
                    enabled: chat.canNavigateForward,
                    help: "Forward"
                ) { chat.navigateForward() }
            }

            if let channel = chat.selectedChannel {
                HStack(spacing: 8) {
                    ChatChannelIconView(channel: channel, size: 18)
                    VStack(alignment: .leading, spacing: 1) {
                    Text(channel.displayTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                        .lineLimit(1)
                    Text(channelSubtitle(channel))
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .lineLimit(1)
                    }
                }
            } else {
                Text("Chat")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
        }
    }

    @ViewBuilder
    private var spacesToolbarLeading: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                navButton(
                    systemName: "chevron.left",
                    enabled: spaces.canNavigateBack,
                    help: "Back"
                ) { Task { await spaces.navigateBack() } }
                navButton(
                    systemName: "chevron.right",
                    enabled: spaces.canNavigateForward,
                    help: "Forward"
                ) { Task { await spaces.navigateForward() } }
            }

            if let space = spaces.selectedSpace {
                VStack(alignment: .leading, spacing: 1) {
                    Text(space.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                        .lineLimit(1)
                    Text(spaces.spaceSubtitle(space))
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .lineLimit(1)
                }
            } else {
                Text("Spaces")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
        }
    }

    private func channelSubtitle(_ channel: ChatChannel) -> String {
        if let desc = channel.description, !desc.isEmpty {
            return desc
        }
        let count = chat.channelMemberCount(for: channel)
        return count == 1 ? "1 member" : "\(count) members"
    }

    private func navButton(
        systemName: String,
        enabled: Bool,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(enabled ? CursorTheme.foregroundMuted : CursorTheme.foregroundDim.opacity(0.35))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(enabled ? CursorTheme.panelBackground : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(help)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundDim)
            TextField(searchPlaceholder, text: searchBinding)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            if module == .chat, !chat.searchQuery.isEmpty {
                clearSearchButton { chat.searchQuery = "" }
            }
            if module == .spaces, !spaces.searchQuery.isEmpty {
                clearSearchButton { spaces.searchQuery = "" }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(CursorTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func clearSearchButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundDim)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var toolbarTrailing: some View {
        HStack(spacing: 8) {
            if module == .chat {
                chatActions
            }
            if module == .spaces {
                spacesActions
            }

            if !auth.workspaceMemberships.isEmpty {
                workspaceMenu
            }
        }
    }

    private var spacesActions: some View {
        HStack(spacing: 6) {
            viewModePicker

            if spaces.selectedSpace != nil {
                toolbarIcon(
                    spaces.selectedSpace?.isPinned == true ? "pin.fill" : "pin",
                    tint: spaces.selectedSpace?.isPinned == true ? CursorTheme.accent : CursorTheme.foregroundMuted
                ) {
                    Task { await spaces.togglePinSelectedSpace() }
                }
                .help("Pin space")

                toolbarIcon(
                    spaces.showTaskPanel ? "sidebar.right" : "sidebar.right.fill",
                    tint: spaces.showTaskPanel ? CursorTheme.accent : CursorTheme.foregroundMuted
                ) {
                    spaces.showTaskPanel.toggle()
                }
                .help("Task panel")
            }

            toolbarIcon(
                spaces.spacesFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                tint: spaces.spacesFocusMode ? CursorTheme.accent : CursorTheme.foregroundMuted
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    spaces.spacesFocusMode.toggle()
                }
            }
            .help(spaces.spacesFocusMode ? "Show sidebars" : "Focus on space")

            if spaces.isOffline {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .help("Offline")
            }

            Button {
                Task { await spaces.reload() }
            } label: {
                Image(systemName: spaces.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 6).fill(CursorTheme.panelBackground))
            }
            .buttonStyle(.plain)
            .help("Refresh")
        }
    }

    private var viewModePicker: some View {
        HStack(spacing: 2) {
            ForEach(SpacesViewModel.TaskViewMode.allCases) { mode in
                Button {
                    spaces.taskView = mode
                } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(spaces.taskView == mode ? CursorTheme.accent : CursorTheme.foregroundMuted)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(spaces.taskView == mode ? CursorTheme.accent.opacity(0.1) : CursorTheme.panelBackground)
                        )
                }
                .buttonStyle(.plain)
                .help(mode.label)
            }
        }
    }

    private var chatActions: some View {
        HStack(spacing: 6) {
            if chat.selectedChannel != nil {
                toolbarIcon(
                    chat.showPinnedPanel ? "pin.fill" : "pin",
                    tint: chat.showPinnedPanel ? CursorTheme.accent : CursorTheme.foregroundMuted
                ) {
                    chat.showPinnedPanel.toggle()
                }
                .help("Pinned messages")
            }

            toolbarIcon(
                chat.chatFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                tint: chat.chatFocusMode ? CursorTheme.accent : CursorTheme.foregroundMuted
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    chat.chatFocusMode.toggle()
                }
            }
            .help(chat.chatFocusMode ? "Show sidebars" : "Focus on chat")

            toolbarIcon("sparkles") { chat.showAISheet = true }
            if let channel = chat.selectedChannel {
                channelOptionsMenu(channel)
            }

            if chat.isOffline {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .help("Offline")
            }

            statusMenu
        }
    }

    private func channelOptionsMenu(_ channel: ChatChannel) -> some View {
        Menu {
            ChatChannelActionsMenu(chat: chat, channel: channel)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(CursorTheme.panelBackground))
        }
        .menuStyle(.borderlessButton)
        .help("Channel options")
    }

    private var workspaceMenu: some View {
        Menu {
            ForEach(auth.workspaceMemberships) { m in
                Button {
                    auth.switchWorkspace(m)
                } label: {
                    Text("\(m.workspace.name) · \(m.role.label)")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(auth.selectedMembership?.workspace.name ?? "Workspace")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .foregroundStyle(CursorTheme.foregroundMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(CursorTheme.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
    }

    private func toolbarIcon(
        _ systemName: String,
        tint: Color = CursorTheme.foregroundMuted,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(CursorTheme.panelBackground)
                )
        }
        .buttonStyle(.plain)
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
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(CursorTheme.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
    }

    private var searchPlaceholder: String {
        switch module {
        case .chat: return "Search in this channel"
        case .spaces, .whiteboard: return "Search spaces and tasks"
        case .mediaMonitoring: return "Search coverage"
        case .settings: return "Search settings"
        }
    }

    private var searchBinding: Binding<String> {
        switch module {
        case .chat:
            return Binding(
                get: { chat.searchQuery },
                set: { chat.searchQuery = $0 }
            )
        case .spaces, .whiteboard:
            return Binding(
                get: { spaces.searchQuery },
                set: { spaces.searchQuery = $0 }
            )
        case .mediaMonitoring, .settings:
            return .constant("")
        }
    }
}
