import SwiftUI

/// Cursor Mac titlebar — channel/space context on the left; search, actions, and profile on the right.
struct LibraryShellHeaderView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel
    @Binding var module: AppModule
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool
    var reservesTrafficLightLeadingInset: Bool = true

    private var rowHeight: CGFloat {
        AppWindowChromeMetrics.unifiedTitlebarRowHeight
    }

    var body: some View {
        titlebarRow
            .frame(height: rowHeight, alignment: .center)
            .frame(maxWidth: .infinity)
            .background(CursorMacShellDesign.titleBarBackground)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(CursorMacShellDesign.border)
                    .frame(height: CursorMacShellDesign.columnDividerWidth)
            }
    }

    private var titlebarRow: some View {
        HStack(alignment: .center, spacing: 12) {
            if reservesTrafficLightLeadingInset {
                Color.clear
                    .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)
            }

            leadingContext
                .frame(maxWidth: .infinity, alignment: .leading)

            if module == .chat, !chat.typingUsers.isEmpty {
                ChatTypingIndicatorView(label: chat.typingSummary)
                    .fixedSize()
            }

            TitlebarChromeActionBar(
                module: $module,
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel,
                placement: .trailing
            )
        }
        .padding(.leading, reservesTrafficLightLeadingInset ? 0 : 14)
        .padding(.trailing, 14)
    }

    @ViewBuilder
    private var leadingContext: some View {
        switch module {
        case .chat:
            chatLeadingContext
        case .spaces:
            spacesLeadingContext
        case .settings:
            Text("Settings")
                .font(CursorMacShellDesign.centerTitleFont)
                .foregroundStyle(CursorMacShellDesign.centerTitleColor)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var chatLeadingContext: some View {
        if let channel = chat.selectedChannel {
            HStack(spacing: 8) {
                ChatChannelIconView(channel: channel, size: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(channel.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CursorMacShellDesign.centerTitleColor)
                        .lineLimit(1)
                    Text(chatChannelSubtitle(channel))
                        .font(.system(size: 11))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                        .lineLimit(1)
                }
            }
        } else {
            Text(auth.selectedWorkspace?.name ?? "Chat")
                .font(CursorMacShellDesign.centerTitleFont)
                .foregroundStyle(CursorMacShellDesign.centerTitleColor)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var spacesLeadingContext: some View {
        if let space = spaces.selectedSpace {
            VStack(alignment: .leading, spacing: 1) {
                Text(space.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CursorMacShellDesign.centerTitleColor)
                    .lineLimit(1)
                Text(spaces.spaceSubtitle(space))
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .lineLimit(1)
            }
        } else {
            Text("Spaces")
                .font(CursorMacShellDesign.centerTitleFont)
                .foregroundStyle(CursorMacShellDesign.centerTitleColor)
                .lineLimit(1)
        }
    }

    private func chatChannelSubtitle(_ channel: ChatChannel) -> String {
        if let desc = channel.description, !desc.isEmpty {
            return desc
        }
        let count = chat.channelMemberCount(for: channel)
        return count == 1 ? "1 member" : "\(count) members"
    }
}
