import SwiftUI

struct ActivityBarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var module: AppModule

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                ForEach(AppModule.mainStrip) { item in
                    moduleButton(item)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 10)

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
        .frame(width: CursorTheme.activityBarWidth)
        .glassSidebar()
    }

    private func moduleButton(_ item: AppModule) -> some View {
        let selected = module == item
        let badge = item == .chat ? chat.totalUnread : 0
        return Button {
            module = item
            tabStore.openFromModule(item, activate: true)
        } label: {
            ZStack(alignment: .topTrailing) {
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

                if badge > 0 {
                    Text(badge > 99 ? "99+" : "\(badge)")
                        .font(ChatClickUpDesign.activityBadgeFont)
                        .foregroundStyle(.white)
                        .padding(.horizontal, badge > 9 ? 4 : 5)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xE5484D))
                        .clipShape(Capsule())
                        .offset(x: 6, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help(item == .chat && badge > 0 ? "\(item.label) · \(badge) unread" : item.label)
    }
}
