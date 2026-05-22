import SwiftUI

/// ClickUp-style Folder → List picker within the active space.
struct SpacesHierarchyBar: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Menu {
                    Button("All lists") { Task { await spaces.selectList(nil) } }
                    ForEach(spaces.lists) { list in
                        Button(list.name) { Task { await spaces.selectList(list.id) } }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.rectangle")
                        Text(selectedListLabel)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .font(.system(size: 12, weight: .medium))
                }

                Menu {
                    ForEach(spaces.folders) { folder in
                        Button(folder.name) { spaces.selectedFolderId = folder.id }
                    }
                    if spaces.folders.isEmpty {
                        Text("No folders").disabled(true)
                    }
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                }
                .help("Folder filter for new lists")

                Spacer()

                HStack(spacing: 6) {
                    TextField("Folder", text: $spaces.newFolderName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .frame(width: 72)
                        .onSubmit { Task { await spaces.createFolder() } }
                    TextField("List", text: $spaces.newListName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .frame(width: 72)
                        .onSubmit { Task { await spaces.createList() } }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(CursorTheme.panelBackground.opacity(0.6))
    }

    private var selectedListLabel: String {
        if let id = spaces.selectedListId,
           let list = spaces.lists.first(where: { $0.id == id }) {
            return list.name
        }
        return "All tasks"
    }
}
