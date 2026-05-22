import SwiftUI

struct ChatMentionPickerSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mention someone")
                .font(.headline)
            TextField("Search people", text: $chat.mentionPickerQuery)
                .textFieldStyle(.roundedBorder)
            List {
                Button {
                    chat.appendComposerToken("@here ")
                    dismiss()
                } label: {
                    Label("@here", systemImage: "person.3")
                }
                Button {
                    chat.appendComposerToken("@channel ")
                    dismiss()
                } label: {
                    Label("@channel", systemImage: "number")
                }
                ForEach(chat.mentionPickerCandidates, id: \.id) { profile in
                    Button {
                        chat.insertMention(for: profile)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            ChatProfileAvatar(
                                profile: profile,
                                displayName: chat.displayName(for: profile.id),
                                size: 28,
                                presence: chat.presence(for: profile.id)
                            )
                            VStack(alignment: .leading) {
                                Text(chat.displayName(for: profile.id))
                                    .font(.system(size: 13, weight: .medium))
                                Text("@\(chat.mentionHandle(for: profile))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(minHeight: 200)
            Button("Close") { dismiss() }
        }
        .padding(20)
        .frame(width: 360, height: 420)
    }
}
