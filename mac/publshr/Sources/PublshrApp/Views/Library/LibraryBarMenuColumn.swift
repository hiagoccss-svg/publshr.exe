import SwiftUI

/// Primary bar menu — app modules only (Chat, Spaces).
struct LibraryBarMenuColumn: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @Binding var module: AppModule

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 3) {
                ForEach(AppModule.mainStrip) { item in
                    navRow(
                        item.label,
                        icon: item.systemImage,
                        selected: module == item
                    ) {
                        switchModule(item)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Spacer(minLength: 0)
        }
        .frame(width: LibraryGlassDesign.barMenuWidth)
        .frame(maxHeight: .infinity)
    }

    private func navRow(
        _ title: String,
        icon: String,
        badge: Int = 0,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .frame(width: 20, alignment: .center)
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                Text(title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                Spacer(minLength: 0)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(LibraryGlassDesign.primaryCTA)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .frame(height: LibraryGlassDesign.barMenuRowHeight)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func switchModule(_ item: AppModule) {
        module = item
        tabStore.openFromModule(item, activate: true)
    }
}
