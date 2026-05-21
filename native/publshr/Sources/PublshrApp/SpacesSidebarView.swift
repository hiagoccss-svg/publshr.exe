import SwiftUI
import PublshrCore

struct SpacesSidebarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Spaces")
                    .font(.headline)
                Spacer()
                Button(action: model.createSpace) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            TextField("Search spaces", text: $model.sidebarSearch)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            List(selection: $model.selectedSpaceID) {
                ForEach(model.workspace.spaces) { space in
                    DisclosureGroup {
                        ForEach(space.folders) { folder in
                            DisclosureGroup(folder.name) {
                                ForEach(folder.lists) { list in
                                    Text(list.name)
                                        .onTapGesture { model.selectedListID = list.id }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: space.colorHex) ?? PublshrTheme.accent)
                                .frame(width: 10, height: 10)
                            Text(space.name)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .tag(space.id)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if s.count == 6 { s = "FF" + s }
        guard let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
