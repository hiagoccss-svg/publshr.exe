import SwiftUI

struct SpacesRootView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                workspaceContent
                if spaces.selectedSpaceId != nil {
                    SpacesQuickAddBar(spaces: spaces)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CursorTheme.editorBackground)

            if spaces.showTaskPanel, spaces.selectedTask != nil {
                Rectangle()
                    .fill(CursorTheme.borderSubtle.opacity(0.5))
                    .frame(width: 1)
                SpacesTaskDetailPanel(spaces: spaces)
                    .frame(width: 320)
            }
        }
        .background(CursorTheme.editorBackground)
        .onAppear { spaces.attach(auth: auth) }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            spaces.attach(auth: auth)
        }
    }

    @ViewBuilder
    private var workspaceContent: some View {
        if spaces.isLoading && spaces.spaces.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = spaces.errorMessage, spaces.spaces.isEmpty {
            emptyError(error)
        } else if spaces.spaces.isEmpty {
            emptyNoSpaces
        } else if spaces.selectedSpace == nil {
            Text("Select a space")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch spaces.taskView {
            case .board:
                SpacesBoardView(spaces: spaces)
            case .list:
                SpacesListView(spaces: spaces)
            case .overview:
                SpacesOverviewView(spaces: spaces)
            }
        }
    }

    private func emptyError(_ error: String) -> some View {
        VStack(spacing: 10) {
            Text("Could not load spaces")
                .font(.system(size: 14, weight: .medium))
            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await spaces.reload() } }
                .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyNoSpaces: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 32))
                .foregroundStyle(CursorTheme.foregroundDim)
            Text("No spaces yet")
                .font(.system(size: 15, weight: .medium))
            Text("Create a space for clients, campaigns, launches, and editorial work — like ClickUp Spaces.")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Inline quick-add for tasks (toolbar holds navigation; composer lives here).
struct SpacesQuickAddBar: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle")
                .font(.system(size: 14))
                .foregroundStyle(CursorTheme.foregroundDim)
            TextField("Add task…", text: $spaces.newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit { Task { await spaces.createTask() } }
            Button {
                Task { await spaces.createTask() }
            } label: {
                Text("Add task")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(spaces.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(CursorTheme.panelBackground)
    }
}
