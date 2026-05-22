import SwiftUI

struct ChatScheduleSendSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule message")
                .font(.headline)
            if let channel = chat.selectedChannel {
                Text("Posting to \(channel.sidebarTitle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            DatePicker("Send at", selection: $chat.scheduleSendAt, in: Date().addingTimeInterval(60)...)
            Text(chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Write your message in the composer first."
                : String(chat.composerText.prefix(120)))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(3)
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Schedule") {
                    Task {
                        await chat.scheduleCurrentMessage()
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
        .onAppear {
            if chat.scheduleSendAt < Date().addingTimeInterval(3600) {
                chat.scheduleSendAt = Date().addingTimeInterval(3600)
            }
        }
    }
}
