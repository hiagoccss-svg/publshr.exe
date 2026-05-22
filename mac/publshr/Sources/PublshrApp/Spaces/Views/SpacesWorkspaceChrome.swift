import SwiftUI

/// Integrated Spaces chrome (one toolbar row + hierarchy) — matches Chat, avoids double bars.
struct SpacesWorkspaceChrome<Content: View>: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var spaces: SpacesViewModel
    var topInset: CGFloat = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)
            mainToolbar
            if spaces.selectedSpaceId != nil {
                SpacesHierarchyBar(spaces: spaces)
            }
            content()
        }
        .background(CursorTheme.editorBackground)
    }

    private var mainToolbar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                navButton("chevron.left", enabled: spaces.canNavigateBack) {
                    Task { await spaces.navigateBack() }
                }
                navButton("chevron.right", enabled: spaces.canNavigateForward) {
                    Task { await spaces.navigateForward() }
                }
            }

            if let space = spaces.selectedSpace {
                VStack(alignment: .leading, spacing: 0) {
                    Text(space.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                        .lineLimit(1)
                    Text(spaces.spaceSubtitle(space))
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .lineLimit(1)
                }
            } else {
                Text("Spaces")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                TextField("Search spaces and tasks", text: $spaces.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(maxWidth: 220)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(CursorTheme.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if spaces.selectedSpace != nil {
                viewModePicker
                chromeIcon(
                    spaces.selectedSpace?.isPinned == true ? "pin.fill" : "pin",
                    accent: spaces.selectedSpace?.isPinned == true
                ) {
                    Task { await spaces.togglePinSelectedSpace() }
                }
                chromeIcon(
                    spaces.showTaskPanel ? "sidebar.right.fill" : "sidebar.right",
                    accent: spaces.showTaskPanel
                ) {
                    spaces.showTaskPanel.toggle()
                }
            }

            chromeIcon(
                spaces.spacesFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                accent: spaces.spacesFocusMode
            ) {
                withAnimation(.easeInOut(duration: 0.18)) { spaces.spacesFocusMode.toggle() }
            }

            Button { Task { await spaces.reload() } } label: {
                Image(systemName: spaces.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            .buttonStyle(.plain)

            if !auth.workspaceMemberships.isEmpty {
                workspaceMenu
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .padding(.bottom, 4)
        .frame(height: CursorTheme.chatToolbarHeight)
    }

    private var viewModePicker: some View {
        HStack(spacing: 2) {
            ForEach(SpacesViewModel.TaskViewMode.allCases) { mode in
                Button { spaces.taskView = mode } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(spaces.taskView == mode ? CursorTheme.accent : CursorTheme.foregroundMuted)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .help(mode.label)
            }
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

    private func navButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(enabled ? CursorTheme.foregroundMuted : CursorTheme.foregroundDim.opacity(0.35))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func chromeIcon(_ symbol: String, accent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(accent ? CursorTheme.accent : CursorTheme.foregroundMuted)
        }
        .buttonStyle(.plain)
    }
}
