import SwiftUI

struct ChatComposerView: View {
    @ObservedObject var chat: ChatViewModel
    var canSendVoiceNotes: Bool = false
    var onAttachFile: (() -> Void)?
    var onVoiceNote: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            if !chat.typingUsers.isEmpty {
                Text(typingLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .bottom, spacing: 8) {
                if chat.permissions.canUploadFiles {
                    Button(action: { onAttachFile?() }) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 15))
                            .foregroundStyle(CursorTheme.foregroundDim)
                    }
                    .buttonStyle(.plain)
                }

                if canSendVoiceNotes {
                    Button(action: { onVoiceNote?() }) {
                        Image(systemName: "mic")
                            .font(.system(size: 15))
                            .foregroundStyle(CursorTheme.foregroundDim)
                    }
                    .buttonStyle(.plain)
                }

                TextField("Message… @mention", text: $chat.composerText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foreground)
                    .lineLimit(1...8)
                    .padding(10)
                    .background(CursorTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(CursorTheme.borderSubtle, lineWidth: 1)
                    )
                    .onChange(of: chat.composerText) { _, _ in
                        chat.scheduleDraftSave()
                    }

                Button {
                    Task { await chat.sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? CursorTheme.foregroundDim
                                : CursorTheme.accent
                        )
                }
                .buttonStyle(.plain)
                .disabled(chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(12)
        .background(CursorTheme.panelBackground)
        .overlay(alignment: .top) {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }

    private var typingLabel: String {
        let names = chat.typingUsers.map(\.displayName)
        if names.count == 1 { return "\(names[0]) is typing…" }
        return "\(names.joined(separator: ", ")) are typing…"
    }
}
