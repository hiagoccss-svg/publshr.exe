import SwiftUI

/// Shared secondary sidebar chrome (Areas / Recent Notes style from the library reference).
enum LibraryUniversalSubmenu {
    static let width: CGFloat = LibraryGlassDesign.sidebarWidth

    static func sectionHeader(_ title: String, onAdd: (() -> Void)? = nil) -> some View {
        HStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .tracking(0.6)
            Spacer(minLength: 0)
            if let onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal + 2)
        .padding(.top, LibraryGlassDesign.sectionLabelTop + 4)
        .padding(.bottom, LibraryGlassDesign.sectionLabelBottom)
    }

    static func row(
        title: String,
        icon: String? = nil,
        trailing: String? = nil,
        badge: Int = 0,
        selected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                        .frame(width: 14, alignment: .center)
                }
                Text(title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LibraryGlassDesign.primaryCTA)
                        .clipShape(Capsule())
                } else if let trailing {
                    Text(trailing)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
            }
            .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
            .padding(.vertical, LibraryGlassDesign.sidebarRowVertical + 1)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }

    static func sectionDivider() -> some View {
        Rectangle()
            .fill(LibraryGlassDesign.hairline)
            .frame(height: 1)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
    }
}

/// Wraps module secondary nav in universal submenu glass + disconnected bottom slot.
struct LibraryUniversalSubmenuContainer<Content: View, Footer: View>: View {
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.content = content
        self.footer = footer
    }

    var body: some View {
        VStack(spacing: 0) {
            content()
                .frame(maxHeight: .infinity)

            footer()
                .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
                .padding(.top, 8)
                .padding(.bottom, 14)
        }
        .frame(maxHeight: .infinity)
        .frame(width: LibraryUniversalSubmenu.width)
        .glassSidebar()
    }
}

enum LibraryRelativeTime {
    static func string(since date: Date?) -> String? {
        guard let date else { return nil }
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(max(1, seconds))s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        if days < 7 { return "\(days)d" }
        let weeks = days / 7
        if weeks < 5 { return "\(weeks)w" }
        return nil
    }
}
