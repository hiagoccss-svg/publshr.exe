import SwiftUI

/// Primary bar menu — app modules only (Chat, Spaces).
struct ActivityBarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @Binding var module: AppModule

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                ForEach(AppModule.mainStrip) { item in
                    moduleButton(item)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
        .frame(width: LibraryGlassDesign.barMenuWidth)
        .glassSidebar()
    }

    private func moduleButton(_ item: AppModule) -> some View {
        barQuickRow(
            title: item.label,
            icon: item.systemImage,
            badge: 0,
            selected: module == item
        ) {
            module = item
            tabStore.openFromModule(item, activate: true)
        }
    }

    private func barQuickRow(
        title: String,
        icon: String,
        badge: Int,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .regular))
                    .frame(width: 18, alignment: .center)
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                Text(title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LibraryGlassDesign.primaryCTA)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
            .frame(height: LibraryGlassDesign.barMenuRowHeight)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
