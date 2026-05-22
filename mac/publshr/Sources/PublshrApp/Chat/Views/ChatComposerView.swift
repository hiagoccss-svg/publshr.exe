import SwiftUI

struct ChatComposerView: View {
    @ObservedObject var chat: ChatViewModel
    var canSendVoiceNotes: Bool = false
    var onAttachFile: (() -> Void)?
    var onVoiceNote: (() -> Void)?

    private static let quickEmojis = ["👍", "❤️", "😂", "🎉", "👀", "✅"]

    var body: some View {
        VStack(spacing: 4) {
            if !chat.canPostInSelectedChannel {
                announcementBanner
            }
            if let reply = chat.replyingTo {
                replyBanner(reply)
            }
            if !chat.typingUsers.isEmpty {
                ChatTypingIndicatorView(label: chat.typingSummary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            composerToolbar
                .padding(.horizontal, 16)
                .padding(.top, 4)

            HStack(alignment: .bottom, spacing: 10) {
                TextField(composerPlaceholder, text: $chat.composerText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foreground)
                    .lineLimit(1...6)
                    .disabled(!chat.canPostInSelectedChannel)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                            .background(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(LibraryGlassDesign.hairline, lineWidth: 1)
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
                .disabled(
                    !chat.canPostInSelectedChannel
                        || chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .padding(.top, 6)
            .opacity(chat.canPostInSelectedChannel ? 1 : 0.45)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .background(Color.clear)
    }

    /// ClickUp-style composer actions — mention, emoji, attach, voice, schedule.
    private var composerToolbar: some View {
        HStack(spacing: 4) {
            composerIcon("at") {
                chat.openMentionPicker()
            }
            .help("Mention someone")

            Menu {
                ForEach(Self.quickEmojis, id: \.self) { emoji in
                    Button(emoji) {
                        chat.composerText += emoji
                    }
                }
            } label: {
                composerIconLabel("face.smiling")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Add emoji")

            if chat.permissions.canUploadFiles {
                composerIcon("paperclip") { onAttachFile?() }
                    .help("Attach file")
            }
            if canSendVoiceNotes {
                composerIcon("mic") { onVoiceNote?() }
                    .help("Voice note")
            }

            composerIcon("clock") {
                chat.scheduleSendAt = Date().addingTimeInterval(3600)
                chat.showScheduleSendSheet = true
            }
            .help("Schedule send")

            Spacer(minLength: 0)

            if let channel = chat.selectedChannel {
                Text(channel.sidebarTitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .lineLimit(1)
            }
        }
        .opacity(chat.canPostInSelectedChannel ? 1 : 0.45)
    }

    private var announcementBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "megaphone.fill")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
            Text("Only admins can post in this channel.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundMuted)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var composerPlaceholder: String {
        if let channel = chat.selectedChannel {
            return "Message \(channel.sidebarTitle)…"
        }
        return "Message…"
    }

    private func replyBanner(_ message: ChatMessage) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(CursorTheme.accent)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to \(chat.displayName(for: message.userId))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CursorTheme.foreground)
                Text(message.body ?? "")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                chat.cancelReply()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func composerIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            composerIconLabel(systemName)
        }
        .buttonStyle(.plain)
    }

    private func composerIconLabel(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14))
            .foregroundStyle(CursorTheme.foregroundMuted)
            .frame(width: 28, height: 28)
    }

}
