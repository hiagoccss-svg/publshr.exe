import SwiftUI

struct ActivityBarView: View {
    @Binding var module: AppModule
    var topInset: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            Color.clear.frame(height: topInset)

            ForEach(AppModule.mainStrip) { item in
                moduleButton(item)
            }

            Spacer()

            moduleButton(.settings)
        }
        .frame(maxHeight: .infinity)
        .background(CursorTheme.activityBar)
    }

    private func moduleButton(_ item: AppModule) -> some View {
        let selected = module == item
        return Button {
            module = item
        } label: {
            Image(systemName: item.systemImage)
                .font(.system(size: item == .settings ? 17 : 19))
                .symbolRenderingMode(.hierarchical)
                .frame(width: CursorTheme.activityBarWidth, height: 44)
                .foregroundStyle(selected ? CursorTheme.activityBarForeground : CursorTheme.activityBarForegroundDim)
                .background(
                    selected
                        ? Color.white.opacity(0.12)
                        : Color.clear
                )
                .overlay(alignment: .leading) {
                    if selected {
                        Rectangle()
                            .fill(CursorTheme.accent)
                            .frame(width: 2)
                    }
                }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help(item.label)
    }
}
