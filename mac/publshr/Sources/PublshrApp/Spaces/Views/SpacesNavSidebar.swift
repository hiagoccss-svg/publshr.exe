import SwiftUI

struct SpacesNavSidebar: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Spaces")

            ScrollView {
                VStack(spacing: 2) {
                    let pinned = spaces.filteredSpaces.filter(\.isPinned)
                    let rest = spaces.filteredSpaces.filter { !$0.isPinned }
                    if !pinned.isEmpty {
                        subsectionLabel("Pinned")
                        ForEach(pinned) { space in
                            spaceRow(space)
                        }
                    }
                    if !rest.isEmpty {
                        if !pinned.isEmpty { subsectionLabel("All") }
                        ForEach(rest) { space in
                            spaceRow(space)
                        }
                    }
                    if spaces.filteredSpaces.isEmpty && !spaces.searchQuery.isEmpty {
                        Text("No matches")
                            .font(.system(size: 11))
                            .foregroundStyle(CursorTheme.foregroundDim)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.vertical, 4)
            }

            createSpaceField
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(CursorTheme.foregroundDim)
            .tracking(0.5)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }

    private func subsectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(CursorTheme.foregroundDim.opacity(0.85))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }

    private func spaceRow(_ space: SpaceRecord) -> some View {
        let selected = spaces.selectedSpaceId == space.id
        return Button {
            Task { await spaces.selectSpace(space.id) }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(SpaceColor(hex: space.color))
                    .frame(width: 8, height: 8)
                Text(space.name)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if space.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
            }
            .frame(height: CursorTheme.chatSidebarRowHeight)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selected ? CursorTheme.accent.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    private var createSpaceField: some View {
        HStack(spacing: 8) {
            TextField("New space", text: $spaces.newSpaceName)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(CursorTheme.panelBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onSubmit { Task { await spaces.createSpace() } }

            Button {
                Task { await spaces.createSpace() }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .background(CursorTheme.panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(spaces.newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(12)
    }
}

enum SpaceColor {
    static func hex(_ hex: String) -> Color {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt64(s, radix: 16) else {
            return CursorTheme.accent
        }
        return Color(hex: UInt32(value))
    }
}
