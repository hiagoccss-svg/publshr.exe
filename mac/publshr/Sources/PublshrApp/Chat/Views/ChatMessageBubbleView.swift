import SwiftUI
import AppKit

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
    var showReadReceipts: Bool = false
    var seenByLabel: String?
    var onRetry: (() -> Void)?
    var onReply: (() -> Void)?
    var onReaction: ((String) -> Void)?
    var onThread: (() -> Void)?
    var onPin: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var assigneeName: String?
    var onAssign: (() -> Void)?

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
                if let assigneeName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 10))
                        Text("Assigned to \(assigneeName)")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(CursorTheme.accent)
                    .padding(.top, 2)
                }
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
                if let seen = seenByLabel, isOwn, showReadReceipts {
                    Text(seen)
                        .font(.system(size: 10))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, showAvatar ? 4 : 1)
        .contextMenu {
            Button("Reply") { onReply?() }
            Button("Reply in thread") { onThread?() }
            Menu("React") {
                ForEach(ChatQuickReaction.allCases, id: \.rawValue) { r in
                    Button(r.rawValue) { onReaction?(r.rawValue) }
                }
            }
            Button("Pin") { onPin?() }
            if onAssign != nil {
                Button("Assign to…") { onAssign?() }
            }
            if isOwn, let body = message.body, !body.isEmpty, !message.isDeleted {
                Button("Edit") { onEdit?() }
            }
            if canDeleteMessage {
                Button(deleteActionTitle, role: .destructive) { onDelete?() }
            }
        }
    }

    private var voiceAttachment: ChatAttachment? {
        message.attachments.first { $0.isVoice }
    }

    private var primaryAttachment: ChatAttachment? {
        message.attachments.first
    }

    private var canDeleteMessage: Bool {
        isOwn && !message.isDeleted && onDelete != nil
    }

    private var deleteActionTitle: String {
        if message.attachments.contains(where: \.isVideo) {
            return "Delete video"
        }
        if message.attachments.contains(where: \.isVoice) {
            return "Delete voice note"
        }
        if message.attachments.contains(where: \.isImage) {
            return "Delete image"
        }
        return "Delete message"
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
            if voiceAttachment == nil, !message.attachments.isEmpty {
                attachmentContent
                    .libraryCard(glass: true, padding: 10)
                    .padding(.top, 4)
            }
        } else if !message.attachments.isEmpty, voiceAttachment == nil {
            attachmentContent
                .libraryCard(glass: true, padding: 10)
        }
    }

    @ViewBuilder
    private var attachmentContent: some View {
        if let video = message.attachments.first(where: \.isVideo),
           let urlString = video.url,
           let url = URL(string: urlString) {
            videoAttachmentView(url: url, name: video.name)
        } else if let image = message.attachments.first(where: \.isImage),
                  let urlString = image.url,
                  let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit().frame(maxHeight: 220).clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    attachmentLabel(icon: "photo", title: image.name ?? "Image")
                default:
                    ProgressView().controlSize(.small)
                }
            }
        } else if let att = primaryAttachment {
            attachmentLabel(
                icon: att.isVideo ? "video.fill" : "paperclip",
                title: att.name ?? "Attachment"
            )
        }
    }

    private func videoAttachmentView(url: URL, name: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "video.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(CursorTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name ?? "Video")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CursorTheme.foreground)
                    Text(url.lastPathComponent)
                        .font(.system(size: 10))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Button("Open") {
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func attachmentLabel(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
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
            if isOwn, showReadReceipts {
                Image(systemName: message.localStatus == .seen ? "checkmark.circle.fill" : "checkmark")
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
        }
    }
}
