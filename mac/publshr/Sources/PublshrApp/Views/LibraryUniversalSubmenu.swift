import SwiftUI

/// Shared secondary sidebar chrome (Areas / Recent Notes style from the library reference).
enum LibraryUniversalSubmenu {
    static let width: CGFloat = LibraryGlassDesign.sidebarWidthWide

    static func sectionHeader(_ title: String, onAdd: (() -> Void)? = nil) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            Spacer(minLength: 0)
            if let onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Add \(title.lowercased())")
            }
        }
        .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal + 2)
        .padding(.top, 8)
        .padding(.bottom, 3)
    }

    static func sectionDivider() -> some View {
        Rectangle()
            .fill(LibraryGlassDesign.hairline)
            .frame(height: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
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
                .frame(minHeight: 0, maxHeight: .infinity)

            footer()
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 10)
        }
        .frame(width: width)
        .frame(minHeight: 0, maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)
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
