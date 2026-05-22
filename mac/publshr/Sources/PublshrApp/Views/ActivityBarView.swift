import SwiftUI

struct ActivityBarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @Binding var module: AppModule

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                ForEach(AppModule.mainStrip) { item in
                    moduleButton(item)
                }
            }
            .padding(.top, 8)

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
                .font(.system(size: CursorTheme.activityBarIconSize, weight: .regular))
                .symbolRenderingMode(.monochrome)
                .frame(width: CursorTheme.activityBarWidth, height: 28)
                .foregroundStyle(
                    selected ? CursorTheme.accent : CursorTheme.activityBarForegroundDim
                )
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(selected ? CursorTheme.accent.opacity(0.1) : Color.clear)
                        .padding(.horizontal, 8)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help(item.label)
    }
}
