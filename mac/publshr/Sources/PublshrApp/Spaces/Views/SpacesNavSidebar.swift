import SwiftUI

/// Universal submenu for Spaces — workspace list + hierarchy tree.
struct SpacesNavSidebar: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        LibraryUniversalSubmenuContainer {
            VStack(alignment: .leading, spacing: 0) {
                spacesListSection

                if spaces.selectedSpaceId != nil {
                    LibraryUniversalSubmenu.sectionDivider()
                    ScrollView {
                        SpacesHierarchyTreeView(spaces: spaces)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    Spacer(minLength: 0)
                }
            }
        } footer: {
            createSpaceField
        }
    }

    private var spacesListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            LibraryUniversalSubmenu.sectionHeader("Spaces")

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
                        if !pinned.isEmpty { subsectionLabel("All spaces") }
                        ForEach(rest) { space in
                            spaceRow(space)
                        }
                    }
                    if spaces.filteredSpaces.isEmpty && !spaces.searchQuery.isEmpty {
                        Text("No matches")
                            .font(.system(size: 11))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: spaces.selectedSpaceId == nil ? .infinity : 200)
        }
    }

    private func subsectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(LibraryGlassDesign.inkMuted.opacity(0.85))
            .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal + 2)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }

    private func spaceRow(_ space: SpaceRecord) -> some View {
        let selected = spaces.selectedSpaceId == space.id
        return Button {
            tabStore.openFromSpace(space)
            Task { await spaces.selectSpace(space.id) }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(SpaceColor.hex(space.color))
                    .frame(width: 7, height: 7)
                Text(space.name)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if space.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
            }
            .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
            .padding(.vertical, LibraryGlassDesign.sidebarRowVertical + 1)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }

    private var createSpaceField: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let err = spaces.errorMessage, !err.isEmpty {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.error)
                    .lineLimit(3)
            }
            HStack(spacing: 8) {
            TextField("New space", text: $spaces.newSpaceName)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(LibraryGlassDesign.cardGlassFill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onSubmit { Task { await spaces.createSpace() } }

            Button {
                spaces.showNewSpaceSheet = true
            } label: {
                Label("New", systemImage: "plus")
            }
            .buttonStyle(LibraryPrimaryPillButtonStyle())
            }
        }
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
