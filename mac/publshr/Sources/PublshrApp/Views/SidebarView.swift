import SwiftUI

struct SidebarView: View {
    let selection: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title(for: selection))

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(sampleItems(for: selection), id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: icon(for: selection))
                                .font(.system(size: 12))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                                .frame(width: 16)
                            Text(item)
                                .font(.system(size: 13))
                                .foregroundStyle(CursorTheme.foreground)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(Color.clear)
                    }
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .background(CursorTheme.sideBar)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(CursorTheme.sideBarSectionHeader)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CursorTheme.sideBar)
            .overlay(alignment: .bottom) {
                Rectangle().fill(CursorTheme.border).frame(height: 1)
            }
    }

    private func title(for selection: Int) -> String {
        switch selection {
        case 0: return "Explorer"
        case 1: return "Search"
        case 2: return "Source Control"
        case 3: return "Run"
        case 4: return "Extensions"
        default: return "Cursor"
        }
    }

    private func icon(for selection: Int) -> String {
        switch selection {
        case 0: return "doc.text"
        case 1: return "doc.text.magnifyingglass"
        case 2: return "folder"
        default: return "doc"
        }
    }

    private func sampleItems(for selection: Int) -> [String] {
        switch selection {
        case 0:
            return ["publshr", "  Sources", "  Package.swift", "  README.md"]
        case 1:
            return ["Search: workspace", "Replace"]
        case 2:
            return ["Changes", "  README.md"]
        default:
            return ["No items"]
        }
    }
}
