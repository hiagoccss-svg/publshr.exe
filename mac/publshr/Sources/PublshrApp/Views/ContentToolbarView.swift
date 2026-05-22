import SwiftUI

/// Unified toolbar in the main content column only (Cursor Mac — not a full-window top bar).
struct ContentToolbarView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel
    var module: AppModule

    var body: some View {
        HStack(spacing: 10) {
            toolbarLeading

            searchField
                .frame(maxWidth: 360)

            Spacer(minLength: 8)

            toolbarTrailing
        }
        .padding(.leading, 12)
        .padding(.trailing, 14)
        .frame(height: CursorTheme.titleBarHeight)
        .background(CursorTheme.editorBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
        }
    }

    @ViewBuilder
    private var toolbarLeading: some View {
        switch module {
        case .chat:
            if let channel = chat.selectedChannel {
                Text(channel.displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CursorTheme.foreground)
                    .lineLimit(1)
            } else {
                Text("Chat")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
        case .spaces:
            Text(spaces.selectedSpace?.name ?? "Spaces")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
                .lineLimit(1)
        case .settings:
            Text("Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundDim)
            TextField(searchPlaceholder, text: searchBinding)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(CursorTheme.inputBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CursorTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private var toolbarTrailing: some View {
        if module == .chat {
            chatActions
        }

        if !auth.workspaceMemberships.isEmpty {
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
            }
            .menuStyle(.borderlessButton)
        }
    }

    private var chatActions: some View {
        HStack(spacing: 10) {
            toolbarIcon("sparkles") { chat.showAISheet = true }
            toolbarIcon("gearshape") { chat.showPermissionsSheet = true }
            statusMenu
        }
    }

    private func toolbarIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
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
        }
        .menuStyle(.borderlessButton)
    }

    private var searchPlaceholder: String {
        switch module {
        case .chat: return "Search channels and messages"
        case .spaces: return "Search spaces and tasks"
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
        case .spaces, .settings:
            return .constant("")
        }
    }
}
