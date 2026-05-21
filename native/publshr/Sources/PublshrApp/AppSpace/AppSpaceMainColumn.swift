import SwiftUI
import PublshrCore

struct AppSpaceMainColumn: View {
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        VStack(spacing: 0) {
            AppSpaceTopBar()
                .environmentObject(space)
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var content: some View {
        switch space.selection {
        case .inbox:
            InboxView()
                .environmentObject(space)
        case .list(let listID):
            if let list = space.document.lists.first(where: { $0.id == listID }) {
                listContent(list: list)
            } else {
                ContentUnavailableView("List not found", systemImage: "exclamationmark.triangle")
            }
        case .space(let spaceID):
            if let sp = space.space(for: spaceID) {
                SpaceOverviewView(space: sp)
                    .environmentObject(space)
            } else {
                ContentUnavailableView("Space not found", systemImage: "exclamationmark.triangle")
            }
        }
    }

    @ViewBuilder
    private func listContent(list: TaskList) -> some View {
        switch space.viewType {
        case .list:
            TaskListView(list: list)
                .environmentObject(space)
        case .board:
            BoardView(list: list)
                .environmentObject(space)
        case .calendar:
            CalendarView(list: list)
                .environmentObject(space)
        case .table:
            TaskTableView(list: list)
                .environmentObject(space)
        case .timeline, .gantt:
            PlaceholderView(
                title: space.viewType.label,
                message: "Timeline and Gantt views are on the roadmap — List, Board, and Calendar are fully interactive."
            )
        }
    }
}

struct AppSpaceTopBar: View {
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.title2.bold())
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search tasks…", text: $space.searchQuery)
                    .textFieldStyle(.plain)
                    .frame(width: 200)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if space.activeListID != nil {
                Picker("View", selection: $space.viewType) {
                    ForEach(ViewType.allCases, id: \.self) { vt in
                        Label(vt.label, systemImage: vt.systemImage).tag(vt)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)
            }

            Button {
                space.showCreateTask = true
            } label: {
                Label("New Task", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(space.activeListID == nil && space.selection != .inbox)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var title: String {
        switch space.selection {
        case .inbox: return "Inbox"
        case .list(let id):
            return space.document.lists.first { $0.id == id }?.name ?? "List"
        case .space(let id):
            return space.space(for: id)?.name ?? "Space"
        }
    }
}

struct PlaceholderView: View {
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: "clock", description: Text(message))
    }
}

struct SpaceOverviewView: View {
    let space: Space
    @EnvironmentObject private var model: AppSpaceModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label(space.name, systemImage: space.icon)
                    .font(.title)
                    .foregroundStyle(Color(hex: space.colorHex) ?? .accentColor)
                Text("Lists in this space")
                    .font(.headline)
                ForEach(model.lists(in: space.id)) { list in
                    Button {
                        model.selectList(list.id)
                    } label: {
                        HStack {
                            Image(systemName: list.icon)
                            Text(list.name)
                            Spacer()
                            Text("\(model.tasks(for: list.id).count) tasks")
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct InboxView: View {
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(space.inboxTasks(), id: \.id.raw) { task in
                    TaskRowView(task: task, list: space.document.lists.first { $0.id == task.listID })
                        .environmentObject(space)
                        .onTapGesture { space.selectTask(task.id) }
                    Divider().padding(.leading, 16)
                }
            }
            .padding(.vertical, 8)
        }
    }
}
