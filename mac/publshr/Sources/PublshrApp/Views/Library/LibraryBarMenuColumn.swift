import SwiftUI

/// Reference primary column (~200px): CTA pill, module nav, disconnected bottom icons.
struct LibraryBarMenuColumn: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @Binding var module: AppModule
    @Binding var showNewChannel: Bool

    var body: some View {
        VStack(spacing: 0) {
            brandMark
                .padding(.horizontal, 16)
                .padding(.top, barMenuTitlebarTopPadding)
                .padding(.bottom, 10)

            primaryCTA
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            navDivider

            VStack(spacing: 3) {
                navRow("Chat", icon: "bubble.left.and.bubble.right", selected: module == .chat) {
                    switchModule(.chat)
                }
                navRow("Spaces", icon: "square.grid.2x2", selected: module == .spaces) {
                    switchModule(.spaces)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            Spacer(minLength: 0)

            bottomIcons
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
        }
        .frame(width: LibraryGlassDesign.barMenuWidth)
        .frame(maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(2)
        .glassBarMenu()
    }

    private var brandMark: some View {
        HStack(spacing: 8) {
            PublshrBrandLogoView(size: 22, cornerRadius: 5)
            Text("Publshr")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.barMenuInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var primaryCTA: some View {
        switch module {
        case .chat:
            Button { showNewChannel = true } label: {
                Label("New message", systemImage: "plus")
            }
            .buttonStyle(LibraryPrimaryPillButtonStyle())
        case .spaces:
            Button { spaces.showNewSpaceSheet = true } label: {
                Label("New space", systemImage: "plus")
            }
            .buttonStyle(LibraryPrimaryPillButtonStyle())
        case .settings:
            EmptyView()
        }
    }

    private var navDivider: some View {
        Rectangle()
            .fill(LibraryGlassDesign.barMenuHairline)
            .frame(height: 1)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
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
                    .foregroundStyle(selected ? LibraryGlassDesign.barMenuInk : LibraryGlassDesign.barMenuInkSecondary)
                Text(title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? LibraryGlassDesign.barMenuInk : LibraryGlassDesign.barMenuInkSecondary)
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
                    .fill(selected ? LibraryGlassDesign.barMenuSelection : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomIcons: some View {
        HStack {
            Button {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.barMenuInkSecondary)
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                Task { await auth.signOut() }
            } label: {
                Image(systemName: "arrow.right.to.line")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.barMenuInkMuted)
            }
            .buttonStyle(.plain)
        }
    }

    private func switchModule(_ item: AppModule) {
        module = item
        tabStore.openFromModule(item, activate: true)
    }

    /// Align the primary CTA with the macOS traffic-light row (side columns share the titlebar band).
    private var barMenuTitlebarTopPadding: CGFloat {
        let band = AppWindowChromeMetrics.unifiedTitlebarRowHeight
        let pill = LibraryGlassDesign.ctaPillHeight
        return AppWindowChromeMetrics.trafficLightVerticalAlignPadding + max(0, (band - pill) / 2)
    }
}
