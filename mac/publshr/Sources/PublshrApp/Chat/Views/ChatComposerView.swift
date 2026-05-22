import SwiftUI

struct ChatComposerView: View {
    @ObservedObject var chat: ChatViewModel
    var canSendVoiceNotes: Bool = false
    var onAttachFile: (() -> Void)?
    var onVoiceNote: (() -> Void)?

    var body: some View {
        VStack(spacing: 6) {
            if !chat.typingUsers.isEmpty {
                Text(typingLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            HStack(alignment: .bottom, spacing: 10) {
                HStack(spacing: 4) {
                    if chat.permissions.canUploadFiles {
                        composerIcon("paperclip") { onAttachFile?() }
                    }
                    if canSendVoiceNotes {
                        composerIcon("mic") { onVoiceNote?() }
                    }
                }

                TextField("Message… @mention", text: $chat.composerText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(CursorTheme.foreground)
                    .lineLimit(1...8)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(CursorTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(CursorTheme.borderSubtle, lineWidth: 0.5)
                    )
                    .onChange(of: chat.composerText) { _, _ in
                        chat.scheduleDraftSave()
                    }

                Button {
                    Task { await chat.sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? CursorTheme.foregroundDim.opacity(0.5)
                                : CursorTheme.accent
                        )
                }
                .buttonStyle(.plain)
                .disabled(chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CursorTheme.panelBackground)
    }

    private func composerIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }

    private var typingLabel: String {
        let names = chat.typingUsers.map(\.displayName)
        if names.count == 1 { return "\(names[0]) is typing…" }
        return "\(names.joined(separator: ", ")) are typing…"
    }
}
