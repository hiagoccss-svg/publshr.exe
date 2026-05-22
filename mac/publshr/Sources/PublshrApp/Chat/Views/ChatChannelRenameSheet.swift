import SwiftUI

struct ChatChannelRenameSheet: View {
    @ObservedObject var chat: ChatViewModel
    let channel: ChatChannel
    @State private var name: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename channel")
                .font(.system(size: 15, weight: .semibold))
            TextField("Channel name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    Task {
                        await chat.commitRenameChannel(id: channel.id, newName: name)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            var n = channel.name
            if n.hasPrefix("#") { n.removeFirst() }
            name = n
        }
    }
}
