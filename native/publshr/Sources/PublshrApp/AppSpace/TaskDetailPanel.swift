import SwiftUI
import PublshrCore

struct TaskDetailPanel: View {
    let task: TaskItem
    @EnvironmentObject private var space: AppSpaceModel
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var commentDraft = ""
    @State private var checklistDraft = ""

    private var list: TaskList? {
        space.document.lists.first { $0.id == task.listID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                properties
                descriptionSection
                checklistSection
                subtasksSection
                commentsSection
            }
            .padding(16)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
        .onAppear { syncFromTask() }
        .onChange(of: task.id.raw) { _, _ in syncFromTask() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            TextField("Task name", text: $name, axis: .vertical)
                .font(.title3.bold())
                .textFieldStyle(.plain)
                .onSubmit { saveName() }
            Menu {
                Button("Close") { space.selectTask(nil) }
                Divider()
                Button("Delete task", role: .destructive) {
                    space.deleteTask(task.id)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
        }
    }

    private var properties: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let list {
                propertyRow("Status") {
                    Picker("", selection: statusBinding) {
                        ForEach(list.statuses.sorted { $0.order < $1.order }, id: \.id) { s in
                            Text(s.name).tag(s.id)
                        }
                    }
                    .labelsHidden()
                }
            }
            propertyRow("Priority") {
                Picker("", selection: priorityBinding) {
                    ForEach(TaskPriority.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }
                .labelsHidden()
            }
            propertyRow("Due date") {
                Toggle("Set due date", isOn: hasDueBinding)
                if task.dueDate != nil {
                    DatePicker("", selection: dueBinding, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            propertyRow("Assignees") {
                assigneePicker
            }
        }
    }

    private var assigneePicker: some View {
        FlowLayout(spacing: 6) {
            ForEach(space.document.workspace.members) { member in
                let selected = task.assigneeIDs.contains(member.id)
                Button {
                    toggleAssignee(member.id)
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: member.colorHex) ?? .accentColor)
                            .frame(width: 16, height: 16)
                        Text(member.name)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Description")
                .font(.subheadline.weight(.semibold))
            TextEditor(text: $description)
                .frame(minHeight: 80)
                .onChange(of: description) { _, new in
                    space.updateTask(task.id) { $0.description = new }
                }
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Checklist")
                .font(.subheadline.weight(.semibold))
            ForEach(liveTask.checklist) { item in
                Toggle(item.title, isOn: Binding(
                    get: { item.isDone },
                    set: { _ in space.toggleChecklistItem(taskID: task.id, itemID: item.id) }
                ))
            }
            HStack {
                TextField("Add item…", text: $checklistDraft)
                    .onSubmit {
                        space.addChecklistItem(taskID: task.id, title: checklistDraft)
                        checklistDraft = ""
                    }
                Button("Add") {
                    space.addChecklistItem(taskID: task.id, title: checklistDraft)
                    checklistDraft = ""
                }
            }
        }
    }

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subtasks")
                .font(.subheadline.weight(.semibold))
            ForEach(space.subtasks(of: task.id), id: \.id.raw) { sub in
                Button {
                    space.selectTask(sub.id)
                } label: {
                    Text(sub.name)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
            Button("Add subtask") {
                space.createTask(name: "Subtask", listID: task.listID, parentTaskID: task.id)
            }
            .font(.caption)
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comments")
                .font(.subheadline.weight(.semibold))
            ForEach(liveTask.comments) { comment in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(space.member(for: comment.authorID)?.name ?? "User")
                            .font(.caption.weight(.semibold))
                        Text(comment.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(comment.body)
                        .font(.subheadline)
                }
                .padding(8)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            HStack {
                TextField("Write a comment…", text: $commentDraft, axis: .vertical)
                Button("Post") {
                    space.addComment(to: task.id, body: commentDraft)
                    commentDraft = ""
                }
                .disabled(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var liveTask: TaskItem {
        space.task(by: task.id) ?? task
    }

    private func propertyRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            content()
            Spacer()
        }
    }

    private func syncFromTask() {
        let t = liveTask
        name = t.name
        description = t.description
    }

    private func saveName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        space.updateTask(task.id) { $0.name = trimmed }
    }

    private func toggleAssignee(_ id: UserID) {
        space.updateTask(task.id) { task in
            if task.assigneeIDs.contains(id) {
                task.assigneeIDs.removeAll { $0 == id }
            } else {
                task.assigneeIDs.append(id)
            }
        }
    }

    private var statusBinding: Binding<String> {
        Binding(
            get: { liveTask.statusID },
            set: { space.moveTask(task.id, toStatus: $0) }
        )
    }

    private var priorityBinding: Binding<TaskPriority> {
        Binding(
            get: { liveTask.priority },
            set: { p in space.updateTask(task.id) { $0.priority = p } }
        )
    }

    private var hasDueBinding: Binding<Bool> {
        Binding(
            get: { liveTask.dueDate != nil },
            set: { on in
                space.updateTask(task.id) {
                    $0.dueDate = on ? Calendar.current.date(byAdding: .day, value: 7, to: Date()) : nil
                }
            }
        )
    }

    private var dueBinding: Binding<Date> {
        Binding(
            get: { liveTask.dueDate ?? Date() },
            set: { d in space.updateTask(task.id) { $0.dueDate = d } }
        )
    }
}

/// Simple flow layout for assignee chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, point) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
