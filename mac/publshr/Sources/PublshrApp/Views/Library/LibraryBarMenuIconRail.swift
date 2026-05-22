import SwiftUI

/// Primary column — enterprise module icons only (52px), below the traffic-light header band.
struct LibraryBarMenuIconRail: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var module: AppModule

    var body: some View {
        VStack(spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            ForEach(AppModule.mainStrip) { item in
                moduleIcon(item)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .padding(.horizontal, 6)
        .frame(width: CursorMacShellDesign.barMenuIconRailWidth)
        .frame(maxHeight: .infinity)
    }

    private func moduleIcon(_ item: AppModule) -> some View {
        let selected = module == item
        return Button {
            module = item
            tabStore.openFromModule(item, activate: true)
        } label: {
            TitlebarToolbarSlot {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.systemImage)
                        .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .medium))
                        .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                        .frame(
                            width: AppWindowChromeMetrics.controlSize,
                            height: AppWindowChromeMetrics.controlSize
                        )
                        .background(
                            RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                                .fill(selected ? MacSystemChrome.toolbarPressedFill : Color.clear)
                        )
                    if item == .chat, chat.totalUnread > 0 {
                        Text(chat.totalUnread > 99 ? "99+" : "\(chat.totalUnread)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(LibraryGlassDesign.ink.opacity(0.85)))
                            .offset(x: 6, y: -6)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .help(item.label)
    }
}
