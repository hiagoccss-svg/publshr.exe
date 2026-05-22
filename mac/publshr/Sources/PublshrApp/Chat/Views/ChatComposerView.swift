import SwiftUI

struct ChatComposerView: View {
    @ObservedObject var chat: ChatViewModel
    var canSendVoiceNotes: Bool = false
    var onAttachFile: (() -> Void)?
    var onVoiceNote: (() -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            if !chat.typingUsers.isEmpty {
                ChatTypingIndicatorView(label: chat.typingSummary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            HStack(alignment: .bottom, spacing: 10) {
                HStack(spacing: 2) {
                    if chat.permissions.canUploadFiles {
                        composerIcon("paperclip") { onAttachFile?() }
                    }
                    if canSendVoiceNotes {
                        composerIcon("mic") { onVoiceNote?() }
                    }
                }

                TextField("Message…", text: $chat.composerText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foreground)
                    .lineLimit(1...6)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(CursorTheme.hairline, lineWidth: 1)
                    )
                    .onChange(of: chat.composerText) { _, _ in
                        chat.composerActivityChanged()
                    }

                Button {
                    Task { await chat.sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(
                            chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? CursorTheme.foregroundDim.opacity(0.4)
                                : CursorTheme.accent
                        )
                }
                .buttonStyle(.plain)
                .disabled(chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .padding(.top, 6)
        }
        .background(CursorTheme.chatBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(CursorTheme.hairline)
                .frame(height: 1)
        }
    }

    private func composerIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }

}
