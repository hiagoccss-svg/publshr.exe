import SwiftUI

struct SpacesNavSidebar: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        VStack(spacing: 0) {
            List(selection: spaceSelection) {
                if !pinnedSpaces.isEmpty {
                    Section("Pinned") {
                        ForEach(pinnedSpaces) { space in
                            spaceLabel(space)
                                .tag(space.id as UUID?)
                        }
                    }
                }
                Section("Spaces") {
                    ForEach(regularSpaces) { space in
                        spaceLabel(space)
                            .tag(space.id as UUID?)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Divider()

            Button {
                spaces.showNewSpaceSheet = true
            } label: {
                Label("New Space", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .background(CursorTheme.navSidebar)
    }

    private var pinnedSpaces: [SpaceRecord] {
        spaces.filteredSpaces.filter(\.isPinned)
    }

    private var regularSpaces: [SpaceRecord] {
        spaces.filteredSpaces.filter { !$0.isPinned }
    }

    private var spaceSelection: Binding<UUID?> {
        Binding(
            get: { spaces.selectedSpaceId },
            set: { newId in
                guard let newId else { return }
                Task { await spaces.selectSpace(newId) }
            }
        )
    }

    private func spaceLabel(_ space: SpaceRecord) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(SpaceColor.hex(space.color))
                .frame(width: 8, height: 8)
            Text(space.name)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}
