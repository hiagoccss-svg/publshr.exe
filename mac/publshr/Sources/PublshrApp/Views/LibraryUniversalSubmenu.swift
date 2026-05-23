import SwiftUI

/// Shared secondary sidebar chrome (Areas / Recent Notes style from the library reference).
enum LibraryUniversalSubmenu {
    static let width: CGFloat = LibraryGlassDesign.sidebarWidthWide
    /// Breathing room below the unified titlebar search row (Cursor Mac submenu).
    static let contentTopInset: CGFloat = 6

    static func sectionHeader(_ title: String, onAdd: (() -> Void)? = nil) -> some View {
        HStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .tracking(0.6)
                .lineLimit(1)
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
        .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
        .padding(.top, LibraryGlassDesign.sectionLabelTop)
        .padding(.bottom, LibraryGlassDesign.sectionLabelBottom)
    }

    static func sectionDivider() -> some View {
        Rectangle()
            .fill(LibraryGlassDesign.contentDivider.opacity(0.65))
            .frame(height: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
    }
}

/// Wraps module secondary nav in universal submenu glass + disconnected bottom slot.
struct LibraryUniversalSubmenuContainer<Content: View, Footer: View>: View {
    var width: CGFloat = LibraryUniversalSubmenu.width
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    init(
        width: CGFloat = LibraryUniversalSubmenu.width,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.width = width
        self.content = content
        self.footer = footer
    }

    var body: some View {
        VStack(spacing: 0) {
            content()
                .padding(.top, LibraryUniversalSubmenu.contentTopInset)
                .frame(minHeight: 0, maxHeight: .infinity)

            footer()
                .frame(maxWidth: .infinity, minHeight: ChatClickUpDesign.footerHeight, alignment: .leading)
                .background(LibraryGlassDesign.submenuFooterBackground)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(LibraryGlassDesign.contentDivider.opacity(0.75))
                        .frame(height: 1)
                }
        }
        .frame(width: width)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .layoutPriority(1)
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
