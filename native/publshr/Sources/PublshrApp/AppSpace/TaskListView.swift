import SwiftUI
import PublshrCore

struct TaskListView: View {
    let list: TaskList
    @EnvironmentObject private var space: AppSpaceModel
    @State private var newTaskName = ""
    @FocusState private var addFocused: Bool

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(space.tasksGroupedByStatus(for: list), id: \.0.id) { status, tasks in
                    if !tasks.isEmpty || true {
                        statusHeader(status, count: tasks.count)
                        ForEach(tasks, id: \.id.raw) { task in
                            TaskRowView(task: task, list: list)
                                .environmentObject(space)
                                .onTapGesture { space.selectTask(task.id) }
                                .background(space.selectedTaskID == task.id ? Color.accentColor.opacity(0.08) : .clear)
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                addTaskRow
            }
            .padding(.vertical, 8)
        }
    }

    private func statusHeader(_ status: TaskStatus, count: Int) -> some View {
        HStack(spacing: 8) {
            StatusDot(colorHex: status.colorHex)
            Text(status.name.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private var addTaskRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            TextField("Add task…", text: $newTaskName)
                .textFieldStyle(.plain)
                .focused($addFocused)
                .onSubmit { submitNewTask() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func submitNewTask() {
        let name = newTaskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        space.createTask(name: name, listID: list.id)
        newTaskName = ""
    }
}

struct TaskRowView: View {
    let task: TaskItem
    let list: TaskList?
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        HStack(spacing: 12) {
            statusMenu
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.body)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if let list, space.selection == .inbox {
                        Text(list.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    PriorityBadge(priority: task.priority)
                    ForEach(task.tagNames, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
            DueDateLabel(date: task.dueDate)
            AssigneeAvatars(memberIDs: task.assigneeIDs)
                .environmentObject(space)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var statusMenu: some View {
        if let list {
            Menu {
                ForEach(list.statuses.sorted { $0.order < $1.order }, id: \.id) { status in
                    Button(status.name) {
                        space.moveTask(task.id, toStatus: status.id)
                    }
                }
            } label: {
                StatusDot(colorHex: list.statuses.first { $0.id == task.statusID }?.colorHex ?? "87909E")
                    .frame(width: 20, height: 20)
            }
            .menuStyle(.borderlessButton)
        } else {
            StatusDot(colorHex: "87909E")
        }
    }
}
