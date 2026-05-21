import AppKit
import SwiftUI
import PublshrCore

struct BoardView: View {
    let list: TaskList
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(space.tasksGroupedByStatus(for: list), id: \.0.id) { status, tasks in
                    BoardColumn(status: status, tasks: tasks, list: list)
                        .environmentObject(space)
                }
            }
            .padding(16)
        }
    }
}

private struct BoardColumn: View {
    let status: TaskStatus
    let tasks: [TaskItem]
    let list: TaskList
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusDot(colorHex: status.colorHex)
                Text(status.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tasks, id: \.id.raw) { task in
                        BoardCard(task: task, list: list)
                            .environmentObject(space)
                            .onTapGesture { space.selectTask(task.id) }
                            .onDrag { NSItemProvider(object: task.id.raw as NSString) }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 280)
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .dropDestination(for: String.self) { items, _ in
            guard let raw = items.first,
                  let dragged = space.document.tasks.first(where: { $0.id.raw == raw }) else { return false }
            space.moveTask(dragged.id, toStatus: status.id)
            return true
        }
    }
}

private struct BoardCard: View {
    let task: TaskItem
    let list: TaskList
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(3)
            HStack {
                PriorityBadge(priority: task.priority)
                Spacer()
                AssigneeAvatars(memberIDs: task.assigneeIDs)
                    .environmentObject(space)
            }
            if let due = task.dueDate {
                DueDateLabel(date: due)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(space.selectedTaskID == task.id ? Color.accentColor : .clear, lineWidth: 2)
        )
    }
}
