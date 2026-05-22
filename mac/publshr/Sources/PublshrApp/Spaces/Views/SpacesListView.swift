import SwiftUI

struct SpacesListView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        if spaces.tasks.isEmpty {
            VStack(spacing: 8) {
                Text("No tasks in this space")
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                Button("Create task") {
                    spaces.newTaskTitle = "New task"
                    Task { await spaces.createTask() }
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(spaces.tasks) { task in
                        Button {
                            spaces.selectedTaskId = task.id
                        } label: {
                            HStack {
                                Text(task.title)
                                    .font(.system(size: 13))
                                    .foregroundStyle(CursorTheme.foreground)
                                    .lineLimit(1)
                                Spacer()
                                Text(task.status.label)
                                    .font(.system(size: 10))
                                    .foregroundStyle(CursorTheme.foregroundDim)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                spaces.selectedTaskId == task.id
                                    ? CursorTheme.editorLineHighlight
                                    : Color.clear
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
