import SwiftUI

/// ClickUp Views Bar — Board, List, Calendar, Overview for the active list/space.
struct SpacesViewsBar: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SpacesViewModes.tabOrder) { mode in
                viewTab(mode)
            }
            Spacer(minLength: 8)
            hierarchyQuickActions
        }
        .padding(.horizontal, SpacesClickUpDesign.chromeHorizontalPadding)
        .frame(height: SpacesClickUpDesign.viewsBarHeight)
        .background(CursorTheme.panelBackground.opacity(0.35))
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
        }
    }

    private func viewTab(_ mode: SpacesViewModel.TaskViewMode) -> some View {
        let selected = spaces.taskView == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                spaces.taskView = mode
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 12))
                Text(mode.label)
                    .font(SpacesClickUpDesign.viewsTabFont)
            }
            .foregroundStyle(selected ? CursorTheme.accent : CursorTheme.foregroundMuted)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(selected ? CursorTheme.tabActiveBackground : Color.clear)
            )
            .overlay(alignment: .bottom) {
                if selected {
                    Rectangle()
                        .fill(CursorTheme.accent)
                        .frame(height: 2)
                        .padding(.horizontal, 8)
                }
            }
        }
        .buttonStyle(.plain)
        .help(mode.label)
    }

    private var hierarchyQuickActions: some View {
        HStack(spacing: 6) {
            Menu {
                Button {
                    spaces.newFolderName = "New Folder"
                } label: {
                    Label("New folder", systemImage: "folder.badge.plus")
                }
                Button {
                    spaces.newListName = "List"
                } label: {
                    Label("New list", systemImage: "list.bullet.rectangle.portrait")
                }
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            .menuStyle(.borderlessButton)
            .help("Add folder or list")

            if !spaces.newFolderName.isEmpty {
                inlineField("Folder", text: $spaces.newFolderName) {
                    Task { await spaces.createFolder() }
                }
            }
            if !spaces.newListName.isEmpty {
                inlineField("List", text: $spaces.newListName) {
                    Task { await spaces.createList() }
                }
            }
        }
    }

    private func inlineField(_ placeholder: String, text: Binding<String>, onSubmit: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .frame(width: 100)
                .onSubmit(onSubmit)
            Button(action: onSubmit) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(CursorTheme.editorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
