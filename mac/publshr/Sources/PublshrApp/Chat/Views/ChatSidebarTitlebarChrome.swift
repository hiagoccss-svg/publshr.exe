import SwiftUI

/// ClickUp-style top band for the chat submenu column — search + filters on one titlebar row.
struct ChatSidebarTitlebarChrome: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                TextField("Search channels and people", text: $chat.sidebarSearchQuery)
                    .textFieldStyle(.plain)
                    .font(ChatClickUpDesign.searchFont)
                    .foregroundStyle(LibraryGlassDesign.ink)
                    .lineLimit(1)
                if !chat.sidebarSearchQuery.isEmpty {
                    Button {
                        chat.sidebarSearchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(minWidth: 120, maxWidth: .infinity)

            HStack(spacing: 10) {
                ForEach(ChatSidebarFilter.allCases) { filter in
                    titlebarFilterPill(filter)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity)
    }

    private func titlebarFilterPill(_ filter: ChatSidebarFilter) -> some View {
        let selected = chat.sidebarFilter == filter
        return Button {
            if selected, filter != .all {
                chat.setSidebarFilter(.all)
            } else {
                chat.setSidebarFilter(filter)
            }
        } label: {
            Text(filter.label)
                .font(.system(size: 10, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .overlay(alignment: .bottom) {
                    if selected {
                        Rectangle()
                            .fill(LibraryGlassDesign.ink.opacity(0.35))
                            .frame(height: 1)
                            .offset(y: 4)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
