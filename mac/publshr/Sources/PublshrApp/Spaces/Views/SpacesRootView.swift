import SwiftUI

struct SpacesRootView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        HStack(spacing: 0) {
            workspaceColumn
            if spaces.showTaskPanel, spaces.selectedTask != nil {
                Divider()
                SpacesTaskDetailPanel(spaces: spaces)
                    .frame(width: SpacesNativeDesign.inspectorWidth)
            }
        }
        .background(SpacesNativeDesign.workspaceBackground)
        .onAppear { spaces.attach(auth: auth) }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            spaces.attach(auth: auth)
        }
        .sheet(isPresented: $spaces.showNewSpaceSheet) {
            SpacesNewSpaceSheet(spaces: spaces)
        }
        .sheet(item: $spaces.editingDocument) { doc in
            SpacesDocumentEditorSheet(spaces: spaces, document: doc)
        }
    }

    private var workspaceColumn: some View {
        VStack(spacing: 0) {
            if let error = spaces.errorMessage, !spaces.spaces.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: spaces.isOffline ? "wifi.slash" : "exclamationmark.triangle")
                    Text(error)
                        .font(.system(size: 11))
                        .lineLimit(2)
                    Spacer()
                    Button("Retry") { Task { await spaces.reload() } }
                        .controlSize(.small)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.08))
            }

            workspaceBody
            if spaces.selectedSpaceId != nil {
                SpacesQuickAddBar(spaces: spaces)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var workspaceBody: some View {
        if spaces.isLoading && spaces.spaces.isEmpty {
            ProgressView("Loading spaces…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if spaces.spaces.isEmpty {
            emptyState
        } else if spaces.selectedSpace == nil {
            Text("Select a space from the sidebar")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch spaces.taskView {
            case .board: SpacesBoardView(spaces: spaces)
            case .list: SpacesListView(spaces: spaces)
            case .overview: SpacesOverviewView(spaces: spaces)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Create your first Space")
                .font(.title3.weight(.semibold))
            Text("Organize clients, campaigns, launches, and editorial work in one operational hub — synced live with Supabase.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            Button("New Space") { spaces.showNewSpaceSheet = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SpacesQuickAddBar: View {
    @ObservedObject var spaces: SpacesViewModel
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            TextField("New task title", text: $spaces.newTaskTitle)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .onSubmit { Task { await spaces.createTask() } }
            Button("Add Task") {
                Task { await spaces.createTask() }
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(spaces.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
