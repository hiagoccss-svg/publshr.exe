import SwiftUI
import UniformTypeIdentifiers

struct SpacesBoardView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(SpaceTaskStatus.boardColumns) { status in
                    boardColumn(status)
                }
            }
            .padding(16)
        }
        .background(SpacesNativeDesign.workspaceBackground)
    }

    private func boardColumn(_ status: SpaceTaskStatus) -> some View {
        let items = spaces.tasks(in: status)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(status.label)
                    .font(.system(size: 12, weight: .semibold))
                Text("\(items.count)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(items) { task in
                    taskCard(task)
                }
            }
        }
        .frame(width: SpacesNativeDesign.columnWidth)
        .padding(10)
        .background(SpacesNativeDesign.columnBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onDrop(of: [.plainText], isTargeted: nil) { providers in
            handleDrop(providers, targetStatus: status)
        }
    }

    private func taskCard(_ task: SpaceTaskRecord) -> some View {
        let selected = spaces.selectedTaskId == task.id
        return Button {
            Task { await spaces.selectTask(task.id) }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    if task.priority == .urgent || task.priority == .high {
                        Text(task.priority.label)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(priorityTint(task.priority).opacity(0.15))
                            .foregroundStyle(priorityTint(task.priority))
                            .clipShape(Capsule())
                    }
                    if let assigneeId = task.assigneeId {
                        ChatProfileAvatar(
                            profile: spaces.profile(for: assigneeId),
                            displayName: spaces.displayName(for: assigneeId),
                            size: 18
                        )
                    }
                    if let progress = task.checklistProgressLabel {
                        Text(progress)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(10)
            .background(selected ? SpacesNativeDesign.cardSelected : SpacesNativeDesign.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .onDrag {
            NSItemProvider(object: task.id.uuidString as NSString)
        }
        .contextMenu {
            ForEach(SpaceTaskStatus.boardColumns) { status in
                if status != task.status {
                    Button("Move to \(status.label)") {
                        Task { await spaces.moveTask(task.id, to: status) }
                    }
                }
            }
            Divider()
            Button("Archive", role: .destructive) {
                spaces.selectedTaskId = task.id
                Task { await spaces.archiveSelectedTask() }
            }
        }
    }

    private func priorityTint(_ priority: SpaceTaskPriority) -> Color {
        switch priority {
        case .urgent: return Color(hex: 0xC72E2E)
        case .high: return Color(hex: 0xD97706)
        default: return CursorTheme.accent
        }
    }

    private func handleDrop(_ providers: [NSItemProvider], targetStatus: SpaceTaskStatus) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let raw = object as? String, let taskId = UUID(uuidString: raw) else { return }
            Task { @MainActor in await spaces.moveTask(taskId, to: targetStatus) }
        }
        return true
    }
}
