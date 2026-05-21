import SwiftUI

struct ChatMessageBubbleView: View {
    let message: ChatMessage
    let authorName: String
    let isOwn: Bool
    let showAvatar: Bool
    var onRetry: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if showAvatar {
                avatar
            } else {
                Color.clear.frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(authorName)
                        .font(.system(size: 12, weight: .semibold))
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

                if message.isDeleted {
                    Text("Message deleted")
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(CursorTheme.foregroundDim)
                } else {
                    Text(message.body ?? "")
                        .font(.system(size: 13))
                        .foregroundStyle(CursorTheme.foreground)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(CursorTheme.inputBackground)
                .frame(width: 32, height: 32)
            Text(String(authorName.prefix(1)).uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
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
