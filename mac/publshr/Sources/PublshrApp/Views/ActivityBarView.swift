import SwiftUI

/// Primary bar menu — compact icons or expanded labels; disconnected bottom actions.
struct ActivityBarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var module: AppModule
    @AppStorage("publshr.barMenuExpanded") private var barMenuExpanded = false

    private var barWidth: CGFloat {
        barMenuExpanded
            ? LibraryGlassDesign.activityBarExpandedWidth
            : LibraryGlassDesign.activityBarWidth
    }

    var body: some View {
        VStack(spacing: 0) {
            dateWeatherWidget
                .padding(.horizontal, barMenuExpanded ? 10 : 6)
                .padding(.top, 10)
                .padding(.bottom, 8)

            VStack(spacing: barMenuExpanded ? 4 : 2) {
                ForEach(AppModule.mainStrip) { item in
                    moduleButton(item)
                }
            }
            .padding(.horizontal, barMenuExpanded ? 8 : 4)
            .padding(.bottom, 6)

            Spacer(minLength: 0)

            disconnectedBottomActions
                .padding(.horizontal, barMenuExpanded ? 10 : 8)
                .padding(.bottom, 14)
        }
        .frame(maxHeight: .infinity)
        .frame(width: barWidth)
        .glassSidebar()
    }

    private var dateWeatherWidget: some View {
        let now = Date()
        return VStack(alignment: barMenuExpanded ? .leading : .center, spacing: 3) {
            if barMenuExpanded {
                Text(now.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LibraryGlassDesign.ink)
                Text(now.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.system(size: 10))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            } else {
                Text(now.formatted(.dateTime.day()))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LibraryGlassDesign.ink)
                Text(now.formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 9))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            HStack(spacing: 4) {
                Image(systemName: "cloud.sun")
                    .font(.system(size: barMenuExpanded ? 11 : 10))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                if barMenuExpanded {
                    Text("—")
                        .font(.system(size: 10))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    barMenuExpanded.toggle()
                }
            } label: {
                Image(systemName: barMenuExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .help(barMenuExpanded ? "Compact bar menu" : "Expand bar menu")
        }
        .frame(maxWidth: .infinity, alignment: barMenuExpanded ? .leading : .center)
    }

    private func moduleButton(_ item: AppModule) -> some View {
        let selected = module == item
        let unread = item == .chat ? min(chat.totalUnread, 99) : 0
        return Button {
            module = item
            tabStore.openFromModule(item, activate: true)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 14, weight: .regular))
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 18, alignment: .center)
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)

                if barMenuExpanded {
                    Text(item.label)
                        .font(.system(size: 12, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(LibraryGlassDesign.primaryCTA)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, barMenuExpanded ? LibraryGlassDesign.sidebarRowHorizontal : 0)
            .frame(
                width: barMenuExpanded ? nil : barWidth,
                height: barMenuExpanded ? LibraryGlassDesign.ctaPillHeight - 4 : 28,
                alignment: barMenuExpanded ? .leading : .center
            )
            .frame(maxWidth: barMenuExpanded ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(item.label)
    }

    /// Bottom icons sit in the column but are not joined by a footer bar (reference layout).
    private var disconnectedBottomActions: some View {
        HStack(spacing: 0) {
            Button {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Modules & settings")

            Spacer(minLength: barMenuExpanded ? 8 : 0)

            Button {
                Task { await auth.signOut() }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Sign out")
        }
    }
}
