import SwiftUI

struct SpacesRootView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        HStack(spacing: 0) {
            SpacesNavSidebar(spaces: spaces)
                .frame(width: 220)

            Rectangle()
                .fill(CursorTheme.border)
                .frame(width: 1)

            VStack(spacing: 0) {
                spacesToolbar
                Rectangle().fill(CursorTheme.border).frame(height: 1)
                workspaceContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CursorTheme.editorBackground)

            if spaces.selectedTask != nil {
                Rectangle()
                    .fill(CursorTheme.border)
                    .frame(width: 1)
                SpacesTaskDetailPanel(spaces: spaces)
                    .frame(width: 300)
            }
        }
        .background(CursorTheme.editorBackground)
        .onAppear { spaces.attach(auth: auth) }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            spaces.attach(auth: auth)
        }
    }

    private var spacesToolbar: some View {
        HStack(spacing: 12) {
            Text(spaces.selectedSpace?.name ?? "Spaces")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
                .lineLimit(1)

            Picker("View", selection: $spaces.taskView) {
                ForEach(SpacesViewModel.TaskViewMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 280)

            Spacer()

            HStack(spacing: 6) {
                TextField("New task", text: $spaces.newTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(CursorTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .frame(width: 180)
                    .disabled(spaces.selectedSpaceId == nil)

                Button("Add") {
                    Task { await spaces.createTask() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(spaces.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CursorTheme.titleBar)
    }

    @ViewBuilder
    private var workspaceContent: some View {
        if spaces.isLoading && spaces.spaces.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = spaces.errorMessage, spaces.spaces.isEmpty {
            VStack(spacing: 8) {
                Text("Could not load spaces")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CursorTheme.foreground)
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .multilineTextAlignment(.center)
                Button("Retry") { Task { await spaces.reload() } }
                    .buttonStyle(.bordered)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if spaces.spaces.isEmpty {
            VStack(spacing: 12) {
                Text("No spaces yet")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(CursorTheme.foreground)
                Text("Create a space to organize work like ClickUp — clients, campaigns, and launches.")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
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
}
