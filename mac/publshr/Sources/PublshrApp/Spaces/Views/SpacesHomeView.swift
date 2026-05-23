import SwiftUI

/// ClickUp Spaces Home — matches `SpacesEnterpriseHome.tsx` + `shared/spaces/spaces-home.ts`.
struct SpacesHomeView: View {
    @ObservedObject var spaces: SpacesViewModel

    private var homeFilters: SpacesHomeLogic.Filters {
        SpacesHomeLogic.Filters(
            query: spaces.spacesHomeQuery,
            typeFilter: spaces.spacesHomeTypeFilter,
            showArchived: spaces.spacesHomeShowArchived
        )
    }

    private var sections: [SpacesHomeLogic.Section] {
        SpacesHomeLogic.buildSections(from: spaces.spaces, filters: homeFilters)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                toolbar
                if sections.isEmpty {
                    emptyState
                } else {
                    ForEach(sections) { section in
                        sectionView(section)
                    }
                }
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
                Text("One Space per team or client — use folders and lists for deliverables (ClickUp-style).")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .frame(maxWidth: 520, alignment: .leading)
                Text("Workspace → Space → Folder → List → Task")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(CursorTheme.foregroundMuted.opacity(0.85))
            }
            Spacer()
            Button {
                spaces.showNewSpaceSheet = true
            } label: {
                Label("New Space", systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                TextField("Search spaces…", text: $spaces.spacesHomeQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(CursorTheme.panelBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Picker("Type", selection: $spaces.spacesHomeTypeFilter) {
                Text("All types").tag("all")
                ForEach(SpaceTypeOption.allCases) { type in
                    Text(type.label).tag(type.rawValue)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 140)

            Toggle(isOn: $spaces.spacesHomeShowArchived) {
                Label("Archived", systemImage: "archivebox")
                    .font(.system(size: 11))
            }
            .toggleStyle(.button)
            .controlSize(.small)

            Picker("Layout", selection: $spaces.spacesHomeUseListLayout) {
                Image(systemName: "square.grid.2x2").tag(false)
                Image(systemName: "list.bullet").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 72)
            .labelsHidden()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No spaces match your filters.")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
            Button("Create a Space") { spaces.showNewSpaceSheet = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func sectionView(_ section: SpacesHomeLogic.Section) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            if spaces.spacesHomeUseListLayout {
                VStack(spacing: 8) {
                    ForEach(section.spaces) { space in
                        spaceCard(space, listStyle: true)
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(section.spaces) { space in
                        spaceCard(space, listStyle: false)
                    }
                }
            }
        }
    }

    private func spaceCard(_ space: SpaceRecord, listStyle: Bool) -> some View {
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
                if space.isArchived {
                    Text("Archived")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(CursorTheme.foregroundMuted)
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
            if !listStyle, !space.description.isEmpty {
                Text(space.description)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .lineLimit(2)
            }
            HStack(spacing: 6) {
                Text(SpacesHomeLogic.spaceTypeLabel(space.type))
                    .font(.system(size: 10))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(CursorTheme.panelBackground.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text(space.status.capitalized)
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundMuted)
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
