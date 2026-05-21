import SwiftUI
import PublshrCore

struct TaskTableView: View {
    let list: TaskList
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        Table(space.tasks(for: list.id), selection: tableSelection) {
            TableColumn("Name") { task in
                Text(task.name)
            }
            TableColumn("Status") { task in
                Text(space.status(in: list, id: task.statusID)?.name ?? "—")
            }
            .width(120)
            TableColumn("Priority") { task in
                Text(task.priority.label)
            }
            .width(80)
            TableColumn("Due") { task in
                if let due = task.dueDate {
                    Text(due, style: .date)
                } else {
                    Text("—")
                }
            }
            .width(100)
            TableColumn("Assignees") { task in
                Text(task.assigneeIDs.compactMap { space.member(for: $0)?.name }.joined(separator: ", "))
            }
        }
        .onChange(of: space.selectedTaskID) { _, _ in }
    }

    private var tableSelection: Binding<Set<TaskID>> {
        Binding(
            get: {
                if let id = space.selectedTaskID { return [id] }
                return []
            },
            set: { ids in
                space.selectTask(ids.first)
            }
        )
    }
}
