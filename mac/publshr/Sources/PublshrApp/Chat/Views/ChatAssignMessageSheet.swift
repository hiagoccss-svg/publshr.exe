import SwiftUI

struct ChatAssignMessageSheet: View {
    @ObservedObject var chat: ChatViewModel
    let message: ChatMessage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assign message")
                .font(.headline)
            List {
                Button {
                    Task {
                        await chat.assignMessage(message, to: nil)
                        dismiss()
                    }
                } label: {
                    Text("Unassigned")
                }
                ForEach(chat.selectedChannelMembers) { member in
                    if member.userId != chat.currentUserId {
                        Button {
                            Task {
                                await chat.assignMessage(message, to: chat.profile(for: member.userId))
                                dismiss()
                            }
                        } label: {
                            Text(chat.displayName(for: member.userId))
                        }
                    }
                }
            }
            .frame(minHeight: 180)
            Button("Cancel") { dismiss() }
        }
        .padding(20)
        .frame(width: 320, height: 360)
    }
}
