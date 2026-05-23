import SwiftUI

/// Planner — native inside Publshr.app (shared Supabase `planner_items` with Chat).
struct PlannerModuleView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @State private var newTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if chat.filteredProjects.isEmpty {
                emptyState
            } else {
                List(chat.filteredProjects) { task in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.system(size: 14, weight: .medium))
                        HStack(spacing: 8) {
                            Text(task.status.capitalized)
                                .font(.system(size: 11))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                            if let due = task.dueDate {
                                Text(due, style: .date)
                                    .font(.system(size: 11))
                                    .foregroundStyle(CursorTheme.foregroundMuted)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CursorMacShellDesign.editorColumnBackground)
        .onAppear {
            chat.attach(auth: auth)
            Task { await chat.loadPlannerTasks() }
        }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            Task { await chat.loadPlannerTasks() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Planner")
                    .font(.system(size: 18, weight: .semibold))
                Text("Workspace tasks — same data as Chat → Planner section.")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            Spacer()
            TextField("New item…", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
            Button("Add") {
                let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { return }
                Task {
                    await chat.createPlannerTaskFromFollowUp(title)
                    newTitle = ""
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(20)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 36))
                .foregroundStyle(CursorTheme.foregroundDim)
            Text("No planner items yet")
                .font(.system(size: 15, weight: .medium))
            Text("Add a task above or share items from Chat.")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
