import SwiftUI

struct SpacesMainView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let space = model.selectedSpace {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: space.colorHex) ?? PublshrTheme.accent)
                        .frame(width: 14, height: 14)
                    Text(space.name)
                        .font(.title.bold())
                }

                Text("ClickUp-style Spaces — folders and lists for your work.")
                    .foregroundStyle(PublshrTheme.textSecondary)

                if space.folders.isEmpty {
                    Label("Empty space — add folders from the sidebar", systemImage: "folder")
                        .foregroundStyle(PublshrTheme.textSecondary)
                } else {
                    ForEach(space.folders) { folder in
                        GroupBox(folder.name) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(folder.lists) { list in
                                    HStack {
                                        Image(systemName: "list.bullet")
                                            .foregroundStyle(PublshrTheme.accent)
                                        Text(list.name)
                                        Spacer()
                                        if model.selectedListID == list.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(PublshrTheme.accent)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                    .onTapGesture { model.selectedListID = list.id }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else {
                Label("Select a space from the sidebar", systemImage: "square.grid.2x2")
                    .foregroundStyle(PublshrTheme.textSecondary)
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
