import SwiftUI

/// Titlebar band above the Spaces submenu column — aligns with chat search row.
struct SpacesSidebarTitlebarChrome: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            TextField("Search spaces", text: $spaces.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(LibraryGlassDesign.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
