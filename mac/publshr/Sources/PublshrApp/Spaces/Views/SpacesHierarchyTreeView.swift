import SwiftUI

/// Expandable Folder → List tree (ClickUp home sidebar pattern).
struct SpacesHierarchyTreeView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            subsectionLabel("In this space")

            allTasksRow

            ForEach(spaces.folders) { folder in
                folderSection(folder)
            }

            if !spaces.standaloneLists.isEmpty {
                if !spaces.folders.isEmpty {
                    subsectionLabel("Lists")
                }
                ForEach(spaces.standaloneLists) { list in
                    listRow(list, indent: 0)
                }
            }

            if spaces.folders.isEmpty && spaces.standaloneLists.isEmpty && !spaces.isLoading {
                Text("Add a folder or list from + above")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .padding(.horizontal, SpacesClickUpDesign.sidebarHorizontalPadding + 4)
                    .padding(.vertical, 8)
            }

            documentsSection
        }
        .padding(.bottom, 8)
    }

    private var allTasksRow: some View {
        let selected = spaces.selectedListId == nil
        return treeButton(
            title: "All tasks",
            icon: "tray.full",
            indent: 0,
            selected: selected
        ) {
            Task { await spaces.selectList(nil) }
        }
    }

    private func folderSection(_ folder: SpaceFolderRecord) -> some View {
        let expanded = spaces.isFolderExpanded(folder.id)
        let folderLists = spaces.lists(in: folder.id)
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                Button {
                    spaces.toggleFolderExpanded(folder.id)
                } label: {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .frame(width: SpacesClickUpDesign.treeExpandHitWidth, height: SpacesClickUpDesign.sidebarRowHeight)
                }
                .buttonStyle(.plain)

                treeButton(
                    title: folder.name,
                    icon: "folder.fill",
                    indent: 0,
                    selected: spaces.selectedFolderId == folder.id && spaces.selectedListId == nil
                ) {
                    Task { await spaces.selectFolder(folder.id) }
                }
            }
            .padding(.leading, SpacesClickUpDesign.sidebarHorizontalPadding - 4)

            if expanded {
                ForEach(folderLists) { list in
                    listRow(list, indent: 1)
                }
                addListInFolderRow(folderId: folder.id)
            }
        }
    }

    private func listRow(_ list: SpaceListRecord, indent: Int) -> some View {
        let selected = spaces.selectedListId == list.id
        return treeButton(
            title: list.name,
            icon: "list.bullet",
            indent: indent + (list.folderId == nil ? 0 : 1),
            selected: selected
        ) {
            Task { await spaces.selectList(list.id) }
        }
    }

    private func addListInFolderRow(folderId: UUID) -> some View {
        Button {
            spaces.selectedFolderId = folderId
            spaces.newListName = "List"
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: SpacesClickUpDesign.sidebarIconWidth)
                Text("Add list")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            .frame(height: 26)
            .padding(.leading, rowLeading(indent: 2))
        }
        .buttonStyle(.plain)
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            subsectionLabel("Docs")
            ForEach(spaces.documents.prefix(5)) { doc in
                Button {
                    spaces.editingDocument = doc
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(CursorTheme.accent)
                            .frame(width: SpacesClickUpDesign.sidebarIconWidth)
                        Text(doc.title)
                            .font(.system(size: 12))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .frame(height: 28)
                    .padding(.leading, rowLeading(indent: 0))
                    .padding(.trailing, SpacesClickUpDesign.sidebarHorizontalPadding)
                }
                .buttonStyle(.plain)
            }
            Button {
                spaces.newDocumentTitle = "Untitled"
                Task { await spaces.createDocument(openEditor: true) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: SpacesClickUpDesign.sidebarIconWidth)
                    Text("New doc")
                        .font(.system(size: 12))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
                .frame(height: 28)
                .padding(.leading, rowLeading(indent: 0))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
    }

    private func treeButton(
        title: String,
        icon: String,
        indent: Int,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(selected ? CursorTheme.accent : CursorTheme.foregroundMuted)
                    .frame(width: SpacesClickUpDesign.sidebarIconWidth)
                Text(title)
                    .font(selected ? SpacesClickUpDesign.treeRowSelectedFont : SpacesClickUpDesign.treeRowFont)
                    .foregroundStyle(selected ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(height: SpacesClickUpDesign.sidebarRowHeight)
            .padding(.leading, rowLeading(indent: indent))
            .padding(.trailing, SpacesClickUpDesign.sidebarHorizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: SpacesClickUpDesign.sidebarRowRadius)
                    .fill(selected ? CursorTheme.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }

    private func rowLeading(indent: Int) -> CGFloat {
        SpacesClickUpDesign.sidebarHorizontalPadding
            + CGFloat(indent) * SpacesClickUpDesign.sidebarIndentStep
    }

    private func subsectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(SpacesClickUpDesign.sectionLabelFont)
            .foregroundStyle(CursorTheme.foregroundDim)
            .tracking(0.5)
            .padding(.horizontal, SpacesClickUpDesign.sidebarHorizontalPadding + 4)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }
}
