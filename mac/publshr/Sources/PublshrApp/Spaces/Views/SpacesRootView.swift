import SwiftUI

struct SpacesRootView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var spaces: SpacesViewModel
    var topInset: CGFloat = 0
    var embedInPopOut: Bool = false

    var body: some View {
        SpacesWorkspaceChrome(spaces: spaces, topInset: topInset, embedInPopOut: embedInPopOut) {
            HStack(spacing: 0) {
                workspaceContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if spaces.showTaskPanel, spaces.selectedTask != nil {
                    Rectangle()
                        .fill(CursorTheme.borderSubtle)
                        .frame(width: 1)
                    SpacesTaskDetailPanel(spaces: spaces)
                        .frame(width: SpacesClickUpDesign.inspectorWidth)
                }
            }
        }
        .onAppear { spaces.attach(auth: auth) }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            spaces.attach(auth: auth)
        }
        .sheet(item: $spaces.editingDocument) { doc in
            SpacesDocumentEditorSheet(spaces: spaces, document: doc)
        }
        .sheet(isPresented: Binding(
            get: { spaces.spaceSettingsSpaceId != nil },
            set: { if !$0 { spaces.spaceSettingsSpaceId = nil } }
        )) {
            if let id = spaces.spaceSettingsSpaceId {
                SpacesSpaceSettingsSheet(spaces: spaces, spaceId: id)
            }
        }
    }

    @ViewBuilder
    private var workspaceContent: some View {
        VStack(spacing: 0) {
            Group {
                if spaces.isLoading && spaces.spaces.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = spaces.errorMessage, spaces.spaces.isEmpty {
                    emptyError(error)
                } else if spaces.spaces.isEmpty {
                    emptyNoSpaces
                } else if spaces.selectedSpace == nil {
                    if spaces.spacesHomeOpen || !spaces.spaces.isEmpty {
                        SpacesHomeView(spaces: spaces)
                    } else {
                        Text("Select a space")
                            .font(.system(size: 13))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    switch spaces.taskView {
                    case .board:
                        SpacesBoardView(spaces: spaces)
                    case .list:
                        SpacesListView(spaces: spaces)
                    case .overview:
                        SpacesOverviewView(spaces: spaces)
                    case .calendar:
                        SpacesCalendarView(spaces: spaces)
                    case .whiteboard:
                        SpacesWhiteboardView(spaces: spaces)
                    case .timeline:
                        SpacesTimelineView(spaces: spaces)
                    case .workload:
                        SpacesWorkloadView(spaces: spaces)
                    case .priority:
                        SpacesPriorityMatrixView(spaces: spaces)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if spaces.selectedSpaceId != nil {
                SpacesQuickAddBar(spaces: spaces)
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
            Text("Create a space for clients, campaigns, launches, and editorial work.")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Inline quick-add for tasks (composer below board/list).
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
        .glassDisconnectedFooter()
        .overlay(alignment: .top) {
            Rectangle().fill(LibraryGlassDesign.hairline).frame(height: 1)
        }
    }
}
