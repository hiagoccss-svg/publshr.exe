import SwiftUI

struct SpacesTaskDetailPanel: View {
    @ObservedObject var spaces: SpacesViewModel
    @State private var editTitle = ""
    @State private var editDescription = ""
    @State private var editTags = ""
    @State private var newChecklistItem = ""
    @State private var dueDateEnabled = false
    @State private var dueDate = Date()
    @State private var suppressFieldSync = false

    var body: some View {
        VStack(spacing: 0) {
            inspectorHeader
            if let task = spaces.selectedTask {
                Form {
                    Section("Task") {
                        TextField("Title", text: $editTitle)
                            .onSubmit { Task { await spaces.updateTaskTitle(task.id, title: editTitle) } }
                        TextEditor(text: $editDescription)
                            .frame(minHeight: 80)
                            .onChange(of: editDescription) { _, new in
                                guard !suppressFieldSync else { return }
                                Task { await spaces.updateTaskDescription(task.id, description: new) }
                            }
                    }
                    Section("Workflow") {
                        Picker("Status", selection: statusBinding(task)) {
                            ForEach(SpaceTaskStatus.boardColumns + [.blocked], id: \.self) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        Picker("Priority", selection: priorityBinding(task)) {
                            ForEach(SpaceTaskPriority.allCases) { p in
                                Text(p.label).tag(p)
                            }
                        }
                        assigneeRow(task)
                        Toggle("Due date", isOn: $dueDateEnabled)
                            .onChange(of: dueDateEnabled) { _, on in
                                Task {
                                    await spaces.updateTaskDueDate(task.id, dueDate: on ? Self.isoDate(dueDate) : nil)
                                }
                            }
                        if dueDateEnabled {
                            DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                                .onChange(of: dueDate) { _, d in
                                    Task { await spaces.updateTaskDueDate(task.id, dueDate: Self.isoDate(d)) }
                                }
                        }
                    }
                    Section("Tags") {
                        TextField("comma, separated", text: $editTags)
                            .onSubmit { saveTags(task) }
                    }
                    Section("Checklist") {
                        ForEach(task.checklist) { item in
                            Toggle(item.title, isOn: checklistBinding(task, item: item))
                        }
                        HStack {
                            TextField("New item", text: $newChecklistItem)
                            Button("Add") { addChecklistItem(task) }
                                .disabled(newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    Section("Comments") {
                        ForEach(spaces.comments) { comment in
                            HStack(alignment: .top, spacing: 8) {
                                ChatProfileAvatar(
                                    profile: spaces.profile(for: comment.userId),
                                    displayName: spaces.displayName(for: comment.userId),
                                    size: 24
                                )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(spaces.displayName(for: comment.userId))
                                        .font(.caption.weight(.semibold))
                                    Text(comment.body)
                                        .font(.system(size: 12))
                                }
                            }
                        }
                        HStack {
                            TextField("Comment…", text: $spaces.newCommentText, axis: .vertical)
                                .lineLimit(1...3)
                            Button {
                                Task { await spaces.postComment() }
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .onAppear { syncFromTask(task) }
                .onChange(of: spaces.selectedTaskId) { _, _ in
                    if let t = spaces.selectedTask { syncFromTask(t) }
                }
            }
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private var inspectorHeader: some View {
        HStack {
            Text("Inspector")
                .font(.headline)
            Spacer()
            Button("Archive", role: .destructive) {
                Task { await spaces.archiveSelectedTask() }
            }
            .controlSize(.small)
            Button {
                Task { await spaces.selectTask(nil) }
            } label: {
                Image(systemName: "sidebar.right")
            }
            .help("Close inspector")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func assigneeRow(_ task: SpaceTaskRecord) -> some View {
        Menu {
            Button("Unassigned") { Task { await spaces.updateTaskAssignee(task.id, assigneeId: nil) } }
            ForEach(Array(spaces.profiles.values).sorted(by: { ($0.displayName ?? $0.email) < ($1.displayName ?? $1.email) })) { profile in
                Button(profile.displayName ?? profile.email) {
                    Task { await spaces.updateTaskAssignee(task.id, assigneeId: profile.id) }
                }
            }
        } label: {
            HStack {
                Text("Assignee")
                Spacer()
                if let id = task.assigneeId {
                    Text(spaces.displayName(for: id))
                        .foregroundStyle(.secondary)
                } else {
                    Text("None")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func syncFromTask(_ task: SpaceTaskRecord) {
        suppressFieldSync = true
        editTitle = task.title
        editDescription = task.description
        editTags = task.tags.joined(separator: ", ")
        if let due = task.dueDate, let date = Self.parseDate(due) {
            dueDateEnabled = true
            dueDate = date
        } else {
            dueDateEnabled = false
        }
        Task { @MainActor in suppressFieldSync = false }
    }

    private func saveTags(_ task: SpaceTaskRecord) {
        let tags = editTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if tags != task.tags { Task { await spaces.updateTaskTags(task.id, tags: tags) } }
    }

    private func addChecklistItem(_ task: SpaceTaskRecord) {
        let title = newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        var list = task.checklist
        list.append(SpaceChecklistItem(title: title))
        newChecklistItem = ""
        Task { await spaces.updateTaskChecklist(task.id, checklist: list) }
    }

    private func statusBinding(_ task: SpaceTaskRecord) -> Binding<SpaceTaskStatus> {
        Binding(
            get: { spaces.tasks.first(where: { $0.id == task.id })?.status ?? task.status },
            set: { new in Task { await spaces.moveTask(task.id, to: new) } }
        )
    }

    private func priorityBinding(_ task: SpaceTaskRecord) -> Binding<SpaceTaskPriority> {
        Binding(
            get: { spaces.tasks.first(where: { $0.id == task.id })?.priority ?? task.priority },
            set: { new in Task { await spaces.updateTaskPriority(task.id, priority: new) } }
        )
    }

    private func checklistBinding(_ task: SpaceTaskRecord, item: SpaceChecklistItem) -> Binding<Bool> {
        Binding(
            get: {
                spaces.tasks.first(where: { $0.id == task.id })?
                    .checklist.first(where: { $0.id == item.id })?.done ?? item.done
            },
            set: { done in
                guard var list = spaces.tasks.first(where: { $0.id == task.id })?.checklist,
                      let idx = list.firstIndex(where: { $0.id == item.id }) else { return }
                list[idx].done = done
                Task { await spaces.updateTaskChecklist(task.id, checklist: list) }
            }
        )
    }

    private static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: date)
    }

    private static func parseDate(_ string: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.date(from: string)
    }
}
