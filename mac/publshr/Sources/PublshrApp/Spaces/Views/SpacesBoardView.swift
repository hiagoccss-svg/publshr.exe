import SwiftUI
import UniformTypeIdentifiers

struct SpacesBoardView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(SpaceTaskStatus.boardColumns) { status in
                    column(status)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func column(_ status: SpaceTaskStatus) -> some View {
        let items = spaces.tasks(in: status)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(status.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                Text("\(items.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(CursorTheme.panelBackground)
                    .clipShape(Capsule())
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(items) { task in
                    taskCard(task)
                }
            }
        }
        .frame(width: 248)
        .padding(12)
        .background(CursorTheme.panelBackground.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CursorTheme.foreground)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if task.priority != .none && task.priority != .normal {
                        priorityBadge(task.priority)
                    }
                }

                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let assigneeId = task.assigneeId {
                        ChatProfileAvatar(
                            profile: spaces.profile(for: assigneeId),
                            displayName: spaces.displayName(for: assigneeId),
                            size: 20
                        )
                    }
                    if let progress = task.checklistProgressLabel {
                        Label(progress, systemImage: "checklist")
                            .font(.system(size: 10))
                            .foregroundStyle(CursorTheme.foregroundDim)
                    }
                    if let due = task.dueDate, !due.isEmpty {
                        Label(due, systemImage: "calendar")
                            .font(.system(size: 10))
                            .foregroundStyle(CursorTheme.foregroundDim)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(10)
            .background(selected ? CursorTheme.accent.opacity(0.06) : CursorTheme.inputBackground.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? CursorTheme.accent.opacity(0.35) : Color.clear, lineWidth: 1)
            )
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

    private func priorityBadge(_ priority: SpaceTaskPriority) -> some View {
        Text(priority.label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(priorityColor(priority))
            .clipShape(Capsule())
    }

    private func priorityColor(_ priority: SpaceTaskPriority) -> Color {
        switch priority {
        case .urgent: return Color(hex: 0xC72E2E)
        case .high: return Color(hex: 0xD97706)
        case .low: return Color(hex: 0x6E6E6E)
        default: return CursorTheme.accent
        }
    }

    private func handleDrop(_ providers: [NSItemProvider], targetStatus: SpaceTaskStatus) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let raw = object as? String, let taskId = UUID(uuidString: raw) else { return }
            Task { @MainActor in
                await spaces.moveTask(taskId, to: targetStatus)
            }
        }
        return true
    }
}
