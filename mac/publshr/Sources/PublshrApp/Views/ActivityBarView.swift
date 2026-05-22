import SwiftUI

struct ActivityBarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @Binding var module: AppModule
    var topInset: CGFloat

    private var iconBandTopPadding: CGFloat {
        max(topInset - 4, 8)
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: iconBandTopPadding)

            VStack(spacing: 2) {
                ForEach(AppModule.mainStrip) { item in
                    moduleButton(item)
                }
            }
            .frame(height: CursorTheme.activityBarIconBandHeight, alignment: .top)
            .padding(.top, 4)

            Spacer(minLength: 0)

            moduleButton(.settings)
                .padding(.bottom, 10)
        }
        .frame(maxHeight: .infinity)
        .frame(width: CursorTheme.activityBarWidth)
        .background(CursorTheme.activityBar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(CursorTheme.hairline)
                .frame(width: 1)
        }
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
                .frame(width: CursorTheme.activityBarWidth, height: 32)
                .foregroundStyle(
                    selected ? CursorTheme.accent : CursorTheme.activityBarForegroundDim
                )
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? CursorTheme.accent.opacity(0.12) : Color.clear)
                        .padding(.horizontal, 7)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help(item.label)
    }
}
