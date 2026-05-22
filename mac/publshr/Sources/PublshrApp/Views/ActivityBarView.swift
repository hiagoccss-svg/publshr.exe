import SwiftUI

struct ActivityBarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @Binding var module: AppModule
    var topInset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            // Keep traffic-light zone clear — bar background starts below titlebar controls.
            Color.clear
                .frame(height: topInset)

            VStack(spacing: 4) {
                ForEach(AppModule.mainStrip) { item in
                    moduleButton(item)
                }

                Spacer(minLength: 0)

                moduleButton(.settings)
            }
            .padding(.vertical, 8)
            .frame(maxHeight: .infinity)
            .frame(width: CursorTheme.activityBarWidth)
            .background(CursorTheme.activityBar)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(CursorTheme.border.opacity(0.55))
                    .frame(width: 1)
            }
        }
        .frame(maxHeight: .infinity)
        .frame(width: CursorTheme.activityBarWidth)
    }

    private func moduleButton(_ item: AppModule) -> some View {
        let selected = module == item
        return Button {
            module = item
            tabStore.openFromModule(item, activate: true)
        } label: {
            Image(systemName: item.systemImage)
                .font(.system(size: CursorTheme.activityBarIconSize, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .frame(width: CursorTheme.activityBarWidth, height: 36)
                .foregroundStyle(
                    selected ? CursorTheme.accent : CursorTheme.activityBarForegroundDim
                )
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? CursorTheme.accent.opacity(0.1) : Color.clear)
                        .padding(.horizontal, 6)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help(item.label)
    }
}
