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
        VStack(alignment: .leading, spacing: 0) {
            panelHeader

            if let task = spaces.selectedTask {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        titleSection(task)
                        descriptionSection(task)
                        statusSection(task)
                        prioritySection(task)
                        assigneeSection(task)
                        dueDateSection(task)
                        tagsSection(task)
                        checklistSection(task)
                        commentsSection
                    }
                    .padding(14)
                }
                .onAppear { syncFromTask(task) }
                .onChange(of: spaces.selectedTaskId) { _, _ in
                    if let t = spaces.selectedTask { syncFromTask(t) }
                }
            }
        }
        .background(CursorTheme.panelBackground)
    }

    private var panelHeader: some View {
        HStack {
            Text("Task details")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundDim)
            Spacer()
            Button {
                Task { await spaces.archiveSelectedTask() }
            } label: {
                Image(systemName: "archivebox")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .help("Archive task")
            Button {
                Task { await spaces.selectTask(nil) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func titleSection(_ task: SpaceTaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Title")
            TextField("Task title", text: $editTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .padding(8)
                .background(CursorTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onSubmit { Task { await spaces.updateTaskTitle(task.id, title: editTitle) } }
        }
    }

    private func descriptionSection(_ task: SpaceTaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Description")
            TextEditor(text: $editDescription)
                .font(.system(size: 12))
                .frame(minHeight: 72)
                .padding(6)
                .background(CursorTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onChange(of: editDescription) { _, new in
                    guard !suppressFieldSync, new != task.description else { return }
                    Task { await spaces.updateTaskDescription(task.id, description: new) }
                }
        }
    }

    private func statusSection(_ task: SpaceTaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Status")
            Picker("Status", selection: statusBinding(task)) {
                ForEach(SpaceTaskStatus.boardColumns + [.blocked], id: \.self) { s in
                    Text(s.label).tag(s)
                }
            }
            .labelsHidden()
        }
    }

    private func prioritySection(_ task: SpaceTaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Priority")
            Picker("Priority", selection: priorityBinding(task)) {
                ForEach(SpaceTaskPriority.allCases) { p in
                    Text(p.label).tag(p)
                }
            }
            .labelsHidden()
        }
    }

    private func assigneeSection(_ task: SpaceTaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Assignee")
            Menu {
                Button("Unassigned") {
                    Task { await spaces.updateTaskAssignee(task.id, assigneeId: nil) }
                }
                ForEach(Array(spaces.profiles.values).sorted(by: { ($0.displayName ?? $0.email) < ($1.displayName ?? $1.email) })) { profile in
                    Button {
                        Task { await spaces.updateTaskAssignee(task.id, assigneeId: profile.id) }
                    } label: {
                        Text(profile.displayName ?? profile.email)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if let assigneeId = task.assigneeId {
                        ChatProfileAvatar(
                            profile: spaces.profile(for: assigneeId),
                            displayName: spaces.displayName(for: assigneeId),
                            size: 24
                        )
                        Text(spaces.displayName(for: assigneeId))
                    } else {
                        Text("Unassigned")
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                }
                .font(.system(size: 12))
            }
        }
    }

    private func dueDateSection(_ task: SpaceTaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Due date", isOn: $dueDateEnabled)
                .font(.system(size: 12))
                .onChange(of: dueDateEnabled) { _, enabled in
                    Task {
                        if enabled {
                            await spaces.updateTaskDueDate(task.id, dueDate: Self.isoDate(dueDate))
                        } else {
                            await spaces.updateTaskDueDate(task.id, dueDate: nil)
                        }
                    }
                }
            if dueDateEnabled {
                DatePicker("", selection: $dueDate, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: dueDate) { _, new in
                        Task { await spaces.updateTaskDueDate(task.id, dueDate: Self.isoDate(new)) }
                    }
            }
        }
    }

    private func tagsSection(_ task: SpaceTaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Tags")
            TextField("comma, separated", text: $editTags)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(8)
                .background(CursorTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onSubmit { saveTags(task) }
                .onChange(of: editTags) { _, _ in saveTags(task) }
        }
    }

    private func checklistSection(_ task: SpaceTaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Checklist")
            ForEach(task.checklist) { item in
                Toggle(isOn: checklistBinding(task, item: item)) {
                    Text(item.title)
                        .font(.system(size: 12))
                }
            }
            HStack {
                TextField("Add item", text: $newChecklistItem)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                Button("Add") {
                    addChecklistItem(task)
                }
                .controlSize(.small)
                .disabled(newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Comments")
            ForEach(spaces.comments) { comment in
                HStack(alignment: .top, spacing: 8) {
                    ChatProfileAvatar(
                        profile: spaces.profile(for: comment.userId),
                        displayName: spaces.displayName(for: comment.userId),
                        size: 24
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spaces.displayName(for: comment.userId))
                            .font(.system(size: 11, weight: .semibold))
                        Text(comment.body)
                            .font(.system(size: 12))
                            .foregroundStyle(CursorTheme.foreground)
                        Text(comment.createdAt, style: .relative)
                            .font(.system(size: 10))
                            .foregroundStyle(CursorTheme.foregroundDim)
                    }
                }
            }
            HStack(alignment: .bottom) {
                TextField("Write a comment…", text: $spaces.newCommentText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .lineLimit(1...4)
                Button {
                    Task { await spaces.postComment() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(CursorTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(CursorTheme.foregroundDim)
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
        Task { @MainActor in
            suppressFieldSync = false
        }
    }

    private func saveTags(_ task: SpaceTaskRecord) {
        let tags = editTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if tags != task.tags {
            Task { await spaces.updateTaskTags(task.id, tags: tags) }
        }
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
