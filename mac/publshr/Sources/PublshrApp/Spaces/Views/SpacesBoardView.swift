import SwiftUI

struct SpacesBoardView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(SpaceTaskStatus.boardColumns) { status in
                    column(status)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func column(_ status: SpaceTaskStatus) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(status.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                Spacer()
                Text("\(spaces.tasks(in: status).count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }

            VStack(spacing: 6) {
                ForEach(spaces.tasks(in: status)) { task in
                    taskCard(task)
                }
            }
        }
        .frame(width: 220)
        .padding(10)
        .background(CursorTheme.panelBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CursorTheme.border, lineWidth: 1)
        )
    }

    private func taskCard(_ task: SpaceTaskRecord) -> some View {
        let selected = spaces.selectedTaskId == task.id
        return Button {
            spaces.selectedTaskId = task.id
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CursorTheme.foreground)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.system(size: 10))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(8)
            .background(selected ? CursorTheme.editorLineHighlight : CursorTheme.inputBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(selected ? CursorTheme.accent.opacity(0.5) : CursorTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(SpaceTaskStatus.boardColumns) { status in
                if status != task.status {
                    Button("Move to \(status.label)") {
                        Task { await spaces.moveTask(task.id, to: status) }
                    }
                }
            }
        }
    }
}
