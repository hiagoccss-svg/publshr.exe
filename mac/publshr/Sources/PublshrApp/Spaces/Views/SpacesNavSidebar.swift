import SwiftUI

/// Universal submenu for Spaces — workspace list + hierarchy tree.
struct SpacesNavSidebar: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @ObservedObject var spaces: SpacesViewModel
    var submenuWidth: CGFloat = LibraryUniversalSubmenu.width

    var body: some View {
        LibraryUniversalSubmenuContainer(width: submenuWidth) {
            VStack(alignment: .leading, spacing: 0) {
                if spaces.activeSection == .spaces {
                    spacesListSection
                        .frame(
                            minHeight: 0,
                            maxHeight: spaces.selectedSpaceId == nil ? .infinity : 200
                        )
                } else {
                    sectionContextHint
                }

                if spaces.activeSection == .spaces, spaces.selectedSpaceId != nil {
                    LibraryUniversalSubmenu.sectionDivider()
                    ScrollView {
                        SpacesHierarchyTreeView(spaces: spaces)
                    }
                    .frame(minHeight: 0, maxHeight: .infinity)
                } else {
                    Spacer(minLength: 0)
                }
            }
            .frame(minHeight: 0, maxHeight: .infinity)
        } footer: {
            VStack(spacing: 0) {
                settingsFooterRow
                if spaces.activeSection == .spaces {
                    createSpaceField
                }
            }
        }
    }

    private var sectionContextHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            LibraryUniversalSubmenu.sectionHeader(spaces.activeSection.label)
            Text("Use the workspace panel to manage \(spaces.activeSection.label.lowercased()).")
                .font(.system(size: 11))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
        }
    }

    private var settingsFooterRow: some View {
        Button {
            spaces.setActiveSection(.settings)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: SpacesEnterpriseSection.settings.systemImage)
                    .font(.system(size: 12))
                Text("Settings")
                    .font(.system(size: 12, weight: spaces.activeSection == .settings ? .semibold : .regular))
                Spacer(minLength: 0)
            }
            .foregroundStyle(
                spaces.activeSection == .settings ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary
            )
            .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
            .padding(.vertical, LibraryGlassDesign.sidebarRowVertical + 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }

    private var spacesListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            LibraryUniversalSubmenu.sectionHeader("Spaces")

            ScrollView {
                VStack(spacing: 2) {
                    Button {
                        spaces.openSpacesHome()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 12))
                            Text("Spaces Home")
                                .font(.system(size: 13, weight: spaces.spacesHomeOpen && spaces.selectedSpaceId == nil ? .semibold : .regular))
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(
                            spaces.spacesHomeOpen && spaces.selectedSpaceId == nil
                                ? LibraryGlassDesign.ink
                                : LibraryGlassDesign.inkSecondary
                        )
                        .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
                        .padding(.vertical, LibraryGlassDesign.sidebarRowVertical + 1)
                        .background(
                            RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                                .fill(
                                    spaces.spacesHomeOpen && spaces.selectedSpaceId == nil
                                        ? LibraryGlassDesign.sidebarSelection
                                        : Color.clear
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 4)

                    let pinned = spaces.filteredSpaces.filter(\.isPinned)
                    let rest = spaces.filteredSpaces.filter { !$0.isPinned }
                    if spaces.filteredSpaces.isEmpty {
                        if let err = spaces.errorMessage, !err.isEmpty {
                            Text(err)
                                .font(.system(size: 11))
                                .foregroundStyle(CursorTheme.error)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            Button("Retry") {
                                Task { await spaces.reload() }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .padding(.horizontal, 16)
                        } else if spaces.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .padding(12)
                        } else {
                            Text("No spaces yet")
                                .font(.system(size: 11))
                                .foregroundStyle(LibraryGlassDesign.inkMuted)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    } else {
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
                    }
                    if spaces.filteredSpaces.isEmpty, !spaces.searchQuery.isEmpty {
                        Text("No matches")
                            .font(.system(size: 11))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 0, maxHeight: .infinity)
            .animation(nil, value: spaces.selectedSpaceId)
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
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.error)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
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
                    let name = spaces.newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if name.isEmpty {
                        spaces.showNewSpaceSheet = true
                    } else {
                        Task { await spaces.createSpace() }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LibraryGlassDesign.filterPillInactiveFill)
                        )
                }
                .buttonStyle(.plain)
                .help("Create space")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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
