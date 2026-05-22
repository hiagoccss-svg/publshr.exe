import SwiftUI

struct SpacesNavSidebar: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SPACES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundDim)
                .tracking(0.6)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(spaces.spaces) { space in
                        spaceRow(space)
                    }
                }
                .padding(.horizontal, 6)
            }

            Divider().overlay(CursorTheme.border)

            HStack(spacing: 6) {
                TextField("New space", text: $spaces.newSpaceName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(6)
                    .background(CursorTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Button {
                    Task { await spaces.createSpace() }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .disabled(spaces.newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(10)
        }
        .background(CursorTheme.sideBar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(CursorTheme.border).frame(width: 1)
        }
    }

    private func spaceRow(_ space: SpaceRecord) -> some View {
        let selected = spaces.selectedSpaceId == space.id
        return Button {
            Task { await spaces.selectSpace(space.id) }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: space.color) ?? CursorTheme.accent)
                    .frame(width: 8, height: 8)
                Text(space.name)
                    .font(.system(size: 12, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(selected ? CursorTheme.editorLineHighlight : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}

private extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt64(s, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
