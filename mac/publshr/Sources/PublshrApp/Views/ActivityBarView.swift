import SwiftUI

struct ActivityBarView: View {
    @Binding var module: AppModule

    var body: some View {
        VStack(spacing: 4) {
            ForEach(AppModule.mainStrip) { item in
                moduleButton(item)
            }

            Spacer()

            moduleButton(.settings)
        }
        .background(CursorTheme.activityBar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(CursorTheme.border).frame(width: 1)
        }
    }

    private func moduleButton(_ item: AppModule) -> some View {
        Button {
            module = item
        } label: {
            Image(systemName: item.systemImage)
                .font(.system(size: item == .settings ? 16 : 18))
                .frame(width: 48, height: 48)
                .foregroundStyle(module == item ? CursorTheme.foreground : CursorTheme.foregroundDim)
                .background(
                    module == item
                        ? CursorTheme.sideBar.opacity(0.5)
                        : Color.clear
                )
        }
        .buttonStyle(.plain)
        .help(item.label)
    }
}
