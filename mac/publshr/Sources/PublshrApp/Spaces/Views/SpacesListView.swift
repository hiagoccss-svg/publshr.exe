import SwiftUI

struct SpacesListView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        let items = spaces.filteredTasks
        if items.isEmpty {
            VStack(spacing: 10) {
                Text(spaces.searchQuery.isEmpty ? "No tasks in this space" : "No tasks match your search")
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                if spaces.searchQuery.isEmpty {
                    Button("Create task") {
                        spaces.newTaskTitle = "New task"
                        Task { await spaces.createTask() }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(items) { task in
                        taskRow(task)
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }

    private func taskRow(_ task: SpaceTaskRecord) -> some View {
        let selected = spaces.selectedTaskId == task.id
        return Button {
            Task { await spaces.selectTask(task.id) }
        } label: {
            HStack(spacing: 12) {
                statusDot(task.status)
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.system(size: 13, weight: selected ? .semibold : .regular))
                        .foregroundStyle(CursorTheme.foreground)
                        .lineLimit(1)
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.system(size: 11))
                            .foregroundStyle(CursorTheme.foregroundDim)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let assigneeId = task.assigneeId {
                    ChatProfileAvatar(
                        profile: spaces.profile(for: assigneeId),
                        displayName: spaces.displayName(for: assigneeId),
                        size: 24
                    )
                }
                Text(task.status.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .frame(minWidth: 72, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                selected ? CursorTheme.accent.opacity(0.06) : Color.clear
            )
        }
        .buttonStyle(.plain)
    }

    private func statusDot(_ status: SpaceTaskStatus) -> some View {
        Circle()
            .fill(statusColor(status))
            .frame(width: 8, height: 8)
    }

    private func statusColor(_ status: SpaceTaskStatus) -> Color {
        switch status {
        case .completed, .approved: return Color(hex: 0x22863A)
        case .blocked: return Color(hex: 0xC72E2E)
        case .in_progress: return CursorTheme.accent
        case .review: return Color(hex: 0xD97706)
        default: return CursorTheme.foregroundDim
        }
    }
}
