import SwiftUI

struct ChatLinkPreviewCard: View {
    let link: ChatMessageLink

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.accent)
                Text(link.preview.title ?? link.linkType.rawValue.capitalized)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CursorTheme.foreground)
                Spacer()
            }
            if let status = link.preview.status {
                Text(status)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            HStack(spacing: 12) {
                if let due = link.preview.dueDate {
                    Label(due, systemImage: "calendar")
                        .font(.system(size: 10))
                }
                if let owner = link.preview.owner {
                    Label(owner, systemImage: "person")
                        .font(.system(size: 10))
                }
            }
            .foregroundStyle(CursorTheme.foregroundDim)
        }
        .libraryCard(glass: true, padding: 12)
    }

    private var iconName: String {
        switch link.linkType {
        case .task, .plannerItem: "checklist"
        case .approval: "checkmark.seal"
        case .document: "doc.text"
        case .file: "paperclip"
        default: "link"
        }
    }
}
