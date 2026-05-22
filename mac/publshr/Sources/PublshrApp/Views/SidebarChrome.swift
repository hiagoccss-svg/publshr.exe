import SwiftUI

/// Shared enterprise sidebar row — compact icons, consistent spacing.
struct EnterpriseSidebarRow: View {
    let title: String
    let icon: String
    var selected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(selected ? Color.white : CursorTheme.foregroundMuted)
                    .frame(width: 14, alignment: .center)
                Text(title)
                    .font(.system(size: 12, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Color.white : CursorTheme.foreground)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(selected ? CursorTheme.accent : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Subtle frosted sidebar for chat (less transparent than native `.sidebar` lists).
struct ChatNavSidebarBackground: View {
    var body: some View {
        ZStack {
            CursorTheme.navSidebar
            Rectangle()
                .fill(.regularMaterial)
                .opacity(0.38)
        }
    }
}
