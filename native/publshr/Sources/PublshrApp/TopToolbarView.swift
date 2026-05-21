import SwiftUI
import PublshrCore

struct TopToolbarView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openSettings) private var openSettings
    @ObservedObject private var supabase = SupabaseService.shared

    var body: some View {
        HStack(spacing: 12) {
            Text("Publshr")
                .font(.headline)
                .foregroundStyle(PublshrTheme.textPrimary)

            Picker("Mode", selection: $model.mode) {
                ForEach(WorkspaceMode.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .onChange(of: model.mode) { _, m in
                Task {
                    if m == .chat { await model.loadMessages() }
                    else { await model.loadTasks() }
                }
            }

            if let wid = model.selectedWorkspaceId {
                Picker("Workspace", selection: $model.selectedWorkspaceId) {
                    ForEach(model.workspaces) { w in
                        Text(w.name).tag(Optional(w.id))
                    }
                }
                .frame(maxWidth: 200)
                .onChange(of: model.selectedWorkspaceId) { _, _ in
                    Task { await model.reloadWorkspaceData() }
                }
            }

            TextField("Search", text: $model.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 220)

            Spacer()

            Button { Task { await model.newChannel() } } label: {
                Label("Channel", systemImage: "number")
            }
            .help("New chat channel")

            Button { Task { await model.newSpace() } } label: {
                Label("Space", systemImage: "folder.badge.plus")
            }
            .help("New space")

            Button { Task { await model.newTask() } } label: {
                Label("Task", systemImage: "checkmark.circle")
            }
            .help("New task")

            Menu {
                Text(supabase.profile?.displayName ?? supabase.profile?.email ?? "Account")
                Divider()
                Button("Sign out") {
                    Task { try? await supabase.signOut() }
                }
            } label: {
                Image(systemName: "person.crop.circle")
            }

            Button { openSettings() } label: {
                Image(systemName: "gearshape")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(PublshrTheme.topBar)
        .overlay(alignment: .bottom) { Rectangle().fill(PublshrTheme.border).frame(height: 1) }
    }
}
