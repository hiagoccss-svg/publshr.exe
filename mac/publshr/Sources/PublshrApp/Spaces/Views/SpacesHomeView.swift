import SwiftUI

/// ClickUp Spaces Home — matches `desktop/spaces/.../SpacesHomeView.tsx`.
struct SpacesHomeView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                let active = spaces.spaces.filter { !$0.isArchived }
                let pinned = active.filter(\.isPinned)
                let favourites = active.filter(\.isFavourite).filter { !$0.isPinned }
                let rest = active.filter { !$0.isPinned && !$0.isFavourite }

                if !pinned.isEmpty {
                    spaceSection(title: "Pinned", icon: "pin.fill", spaces: pinned)
                }
                if !favourites.isEmpty {
                    spaceSection(title: "Favorites", icon: "star.fill", spaces: favourites)
                }
                spaceSection(
                    title: pinned.isEmpty && favourites.isEmpty ? nil : "All Spaces",
                    icon: "square.grid.2x2",
                    spaces: rest.isEmpty ? active : rest
                )
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CursorMacShellDesign.editorColumnBackground)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Spaces Home", systemImage: "square.grid.2x2")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                Text("All Spaces")
                    .font(.system(size: 20, weight: .semibold))
                Text("Group departments, clients, and initiatives — Space → Folder → List → Task.")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .frame(maxWidth: 480, alignment: .leading)
            }
            Spacer()
            Button {
                spaces.showNewSpaceSheet = true
            } label: {
                Label("New Space", systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    private func spaceSection(title: String?, icon: String, spaces list: [SpaceRecord]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Label(title.uppercased(), systemImage: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                ForEach(list) { space in
                    spaceCard(space)
                }
            }
        }
    }

    private func spaceCard(_ space: SpaceRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: space.color) ?? CursorTheme.accent)
                    .frame(width: 10, height: 10)
                Text(space.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                if space.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                }
                if space.isFavourite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                }
                Button {
                    spaces.spaceSettingsSpaceId = space.id
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                }
                .buttonStyle(.plain)
            }
            if !space.description.isEmpty {
                Text(space.description)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .lineLimit(2)
            }
            Button("Open") {
                Task {
                    spaces.spacesHomeOpen = false
                    await spaces.selectSpace(space.id)
                    spaces.taskView = spaces.defaultView(for: space.id)
                }
            }
            .font(.system(size: 11, weight: .medium))
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .background(CursorTheme.panelBackground.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(CursorTheme.borderSubtle))
    }
}

private extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        if s.count == 6 { s = "FF" + s }
        guard s.count == 8, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xff) / 255,
            green: Double((v >> 8) & 0xff) / 255,
            blue: Double(v & 0xff) / 255,
            opacity: Double((v >> 24) & 0xff) / 255
        )
    }
}
