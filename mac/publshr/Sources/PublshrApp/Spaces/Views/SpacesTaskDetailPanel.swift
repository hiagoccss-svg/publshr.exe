import SwiftUI

struct SpacesTaskDetailPanel: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Task")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundDim)
                Spacer()
                Button {
                    spaces.selectedTaskId = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(CursorTheme.panelBackground)
            .overlay(alignment: .bottom) {
                Rectangle().fill(CursorTheme.border).frame(height: 1)
            }

            if let task = spaces.selectedTask {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(task.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CursorTheme.foreground)

                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.system(size: 12))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("STATUS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(CursorTheme.foregroundDim)
                            Picker("Status", selection: statusBinding(taskId: task.id, current: task.status)) {
                                ForEach(SpaceTaskStatus.boardColumns + [.blocked], id: \.self) { s in
                                    Text(s.label).tag(s)
                                }
                            }
                            .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("PRIORITY")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(CursorTheme.foregroundDim)
                            Text(task.priority.rawValue.capitalized)
                                .font(.system(size: 12))
                                .foregroundStyle(CursorTheme.foreground)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(CursorTheme.panelBackground)
    }

    private func statusBinding(taskId: UUID, current: SpaceTaskStatus) -> Binding<SpaceTaskStatus> {
        Binding(
            get: { spaces.tasks.first(where: { $0.id == taskId })?.status ?? current },
            set: { newStatus in
                Task { await spaces.moveTask(taskId, to: newStatus) }
            }
        )
    }
}
