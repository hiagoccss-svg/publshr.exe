import SwiftUI

struct ChatMessageBubbleView: View {
    let message: ChatMessage
    let authorName: String
    var authorProfile: Profile?
    var presence: ChatPresenceStatus = .offline
    let isOwn: Bool
    let showAvatar: Bool
    var reactions: [ChatReactionSummary] = []
    var links: [ChatMessageLink] = []
    var threadReplyCount: Int = 0
    var voiceTranscript: String?
    var onRetry: (() -> Void)?
    var onReaction: ((String) -> Void)?
    var onThread: (() -> Void)?
    var onPin: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if showAvatar {
                ChatProfileAvatar(
                    profile: authorProfile,
                    displayName: authorName,
                    size: 36,
                    presence: presence
                )
            } else {
                Color.clear.frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                if showAvatar {
                    headerRow
                }
                contentBody
                ForEach(links) { link in
                    ChatLinkPreviewCard(link: link)
                }
                if let voice = voiceAttachment {
                    ChatVoicePlaybackRow(durationMs: voice.voiceNoteDurationMs ?? 0, transcript: voiceTranscript)
                }
                ChatReactionBarView(summaries: reactions) { emoji in
                    onReaction?(emoji)
                }
                if threadReplyCount > 0 {
                    Button {
                        onThread?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 10))
                            Text("\(threadReplyCount) \(threadReplyCount == 1 ? "reply" : "replies")")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(CursorTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, showAvatar ? 4 : 1)
        .contextMenu {
            Button("Reply in thread") { onThread?() }
            Menu("React") {
                ForEach(ChatQuickReaction.allCases, id: \.rawValue) { r in
                    Button(r.rawValue) { onReaction?(r.rawValue) }
                }
            }
            Button("Pin") { onPin?() }
            if isOwn {
                Button("Edit") { onEdit?() }
                Button("Delete", role: .destructive) { onDelete?() }
            }
        }
    }

    private var voiceAttachment: ChatAttachment? {
        message.attachments.first { $0.type == "voice" }
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            Text(authorName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            Text(message.createdAt, style: .time)
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundDim)
            if message.isEdited {
                Text("(edited)")
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            Spacer(minLength: 0)
            statusIndicator
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        if message.isDeleted {
            Text("Message deleted")
                .font(.system(size: 13))
                .italic()
                .foregroundStyle(CursorTheme.foregroundDim)
        } else if let body = message.body, !body.isEmpty {
            Text(attributedBody(body))
                .font(.system(size: 14))
                .foregroundStyle(CursorTheme.foreground)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, showAvatar ? 0 : 2)
        } else if !message.attachments.isEmpty, voiceAttachment == nil {
            attachmentContent
        }
    }

    @ViewBuilder
    private var attachmentContent: some View {
        if let image = message.attachments.first(where: { $0.type == "image" }),
           let url = URL(string: image.url) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit().frame(maxHeight: 220).clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    attachmentLabel
                default:
                    ProgressView().controlSize(.small)
                }
            }
            Text(image.name)
                .font(.system(size: 10))
                .foregroundStyle(CursorTheme.foregroundDim)
        } else {
            attachmentLabel
        }
    }

    private var attachmentLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "paperclip")
            Text(message.attachments.first?.name ?? "Attachment")
        }
        .font(.system(size: 13))
        .foregroundStyle(CursorTheme.foregroundMuted)
    }

    private func attributedBody(_ body: String) -> AttributedString {
        var result = AttributedString(body)
        for (range, isMention) in ChatMentionParser.highlightRanges(in: body) {
            if isMention, let attrRange = Range(range, in: result) {
                result[attrRange].foregroundColor = .init(CursorTheme.accent)
                result[attrRange].font = .system(size: 14, weight: .semibold)
            }
        }
        return result
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch message.localStatus {
        case .sending:
            ProgressView().controlSize(.small)
        case .failed:
            Button("Retry", action: { onRetry?() })
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.error)
                .buttonStyle(.plain)
        case .sent, .delivered, .seen:
            if isOwn {
                Image(systemName: message.localStatus == .seen ? "checkmark.circle.fill" : "checkmark")
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
        }
    }
}
