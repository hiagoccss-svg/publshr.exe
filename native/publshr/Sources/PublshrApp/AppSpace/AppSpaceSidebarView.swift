import SwiftUI
import PublshrCore

struct AppSpaceSidebarView: View {
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        List(selection: sidebarBinding) {
            Section {
                sidebarRow(
                    title: "Inbox",
                    icon: "tray.fill",
                    tag: SidebarTag.inbox
                )
            }

            Section(space.document.workspace.name) {
                ForEach(space.document.spaces.sorted { $0.order < $1.order }) { sp in
                    spaceSection(sp)
                }
                Button {
                    space.showCreateSpace = true
                } label: {
                    Label("New Space", systemImage: "plus.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("App Space")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    space.showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Sync & settings")
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(.tint)
                Text(space.currentUser?.name ?? "You")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func spaceSection(_ sp: Space) -> some View {
        DisclosureGroup {
            ForEach(space.rootLists(in: sp.id)) { list in
                listRow(list)
            }
            ForEach(space.folders(in: sp.id)) { folder in
                DisclosureGroup(folder.name) {
                    ForEach(space.lists(in: folder.id)) { list in
                        listRow(list)
                    }
                }
            }
            Button("New List") { space.showCreateList = true }
                .font(.caption)
                .buttonStyle(.plain)
        } label: {
            Label(sp.name, systemImage: sp.icon)
                .foregroundStyle(Color(hex: sp.colorHex) ?? .accentColor)
        }
    }

    private func listRow(_ list: TaskList) -> some View {
        sidebarRow(title: list.name, icon: list.icon, tag: .list(list.id))
    }

    private func sidebarRow(title: String, icon: String, tag: SidebarTag) -> some View {
        Label(title, systemImage: icon)
            .tag(tag)
    }

    private var sidebarBinding: Binding<SidebarTag?> {
        Binding(
            get: {
                switch space.selection {
                case .inbox: return .inbox
                case .list(let id): return .list(id)
                case .space(let id): return .space(id)
                }
            },
            set: { tag in
                guard let tag else { return }
                switch tag {
                case .inbox: space.selectInbox()
                case .list(let id): space.selectList(id)
                case .space(let id): space.selection = .space(id)
                }
            }
        )
    }
}

private enum SidebarTag: Hashable {
    case inbox
    case list(ListID)
    case space(SpaceID)
}
