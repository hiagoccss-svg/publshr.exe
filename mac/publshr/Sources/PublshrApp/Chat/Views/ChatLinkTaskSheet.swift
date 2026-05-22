import SwiftUI

struct ChatLinkTaskSheet: View {
    @ObservedObject var chat: ChatViewModel
    let message: ChatMessage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link to existing task")
                .font(.system(size: 15, weight: .semibold))
            if chat.plannerTasks.isEmpty {
                Text("No planner tasks in this workspace yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(chat.plannerTasks) { task in
                            Button {
                                Task {
                                    await chat.linkMessageToPlannerTask(message, task: task)
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(CursorTheme.foreground)
                                        Text(task.status)
                                            .font(.system(size: 11))
                                            .foregroundStyle(CursorTheme.foregroundMuted)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
            }
        }
        .padding(20)
        .frame(width: 400, height: min(420, CGFloat(chat.plannerTasks.count) * 44 + 120))
        .task { await chat.loadPlannerTasks() }
    }
}
