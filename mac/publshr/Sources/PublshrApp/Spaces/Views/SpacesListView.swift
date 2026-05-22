import SwiftUI

struct SpacesListView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        let items = spaces.filteredTasks
        if items.isEmpty {
            ContentUnavailableView(
                spaces.searchQuery.isEmpty ? "No Tasks" : "No Results",
                systemImage: "checklist",
                description: Text(spaces.searchQuery.isEmpty ? "Add a task using the bar below." : "Try a different search.")
            )
        } else {
            List(selection: taskSelection) {
                ForEach(items) { task in
                    HStack(spacing: 10) {
                        statusIcon(task.status)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.system(size: 13, weight: .medium))
                            if !task.description.isEmpty {
                                Text(task.description)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        if let assigneeId = task.assigneeId {
                            ChatProfileAvatar(
                                profile: spaces.profile(for: assigneeId),
                                displayName: spaces.displayName(for: assigneeId),
                                size: 22
                            )
                        }
                        Text(task.status.label)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .frame(width: 72, alignment: .trailing)
                    }
                    .tag(task.id as UUID?)
                }
            }
            .listStyle(.inset)
        }
    }

    private var taskSelection: Binding<UUID?> {
        Binding(
            get: { spaces.selectedTaskId },
            set: { id in Task { await spaces.selectTask(id) } }
        )
    }

    private func statusIcon(_ status: SpaceTaskStatus) -> some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 8))
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: SpaceTaskStatus) -> Color {
        switch status {
        case .completed, .approved: return .green
        case .blocked: return .red
        case .in_progress: return CursorTheme.accent
        case .review: return .orange
        default: return .secondary
        }
    }
}
