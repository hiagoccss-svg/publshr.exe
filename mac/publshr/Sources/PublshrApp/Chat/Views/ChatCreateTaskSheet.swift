import SwiftUI

struct ChatCreateTaskSheet: View {
    @ObservedObject var chat: ChatViewModel
    let message: ChatMessage
    @State private var title: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create task from message")
                .font(.system(size: 15, weight: .semibold))
            TextField("Task title", text: $title)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") {
                    Task {
                        await chat.createTaskFromMessage(message, title: title)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear {
            let body = (message.body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            title = String(body.prefix(120))
        }
    }
}
