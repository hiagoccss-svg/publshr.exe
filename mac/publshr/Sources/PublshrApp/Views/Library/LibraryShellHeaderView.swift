import SwiftUI

/// Cursor Mac titlebar — center context title; trailing search, command, profile only.
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

            Spacer(minLength: 8)

            Text(centerTitle)
                .font(CursorMacShellDesign.centerTitleFont)
                .foregroundStyle(CursorMacShellDesign.centerTitleColor)
                .lineLimit(1)

            Spacer(minLength: 8)

            TitlebarChromeActionBar(
                module: $module,
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel,
                placement: .trailing
            )
        }
        .padding(.trailing, 14)
    }

    private var centerTitle: String {
        switch module {
        case .chat:
            if let channel = chat.selectedChannel {
                return channel.displayTitle
            }
            return auth.selectedWorkspace?.name ?? "Chat"
        case .spaces:
            return spaces.selectedSpace?.name ?? "Spaces"
        case .settings:
            return "Settings"
        }
    }
}
