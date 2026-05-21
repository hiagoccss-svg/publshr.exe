import SwiftUI

struct ActivityBarView: View {
    @Binding var selection: Int

    private let items: [(String, String)] = [
        ("folder", "Explorer"),
        ("magnifyingglass", "Search"),
        ("point.3.connected.trianglepath.dotted", "Source Control"),
        ("play.rectangle", "Run"),
        ("square.grid.2x2", "Extensions"),
        ("sparkles", "Cursor"),
    ]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    selection = index
                } label: {
                    Image(systemName: item.0)
                        .font(.system(size: 18))
                        .frame(width: 48, height: 48)
                        .foregroundStyle(selection == index ? CursorTheme.foreground : CursorTheme.foregroundDim)
                        .background(
                            selection == index
                                ? CursorTheme.sideBar.opacity(0.5)
                                : Color.clear
                        )
                }
                .buttonStyle(.plain)
                .help(item.1)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .background(CursorTheme.activityBar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(CursorTheme.border).frame(width: 1)
        }
    }
}
