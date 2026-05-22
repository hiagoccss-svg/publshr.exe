import SwiftUI

/// ClickUp-style typing indicator with animated dots.
struct ChatTypingIndicatorView: View {
    let label: String
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(CursorTheme.accent.opacity(0.7))
                        .frame(width: 5, height: 5)
                        .offset(y: phase == i ? -3 : 0)
                }
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(LibraryGlassDesign.cardGlassFill.opacity(0.85))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(CursorTheme.borderSubtle, lineWidth: 1))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

/// Channel strip under workspace header — title, search, pin (ClickUp conversation chrome).
struct ChatChannelStatusBar: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        HStack(spacing: 10) {
            if let channel = chat.selectedChannel {
                ChatChannelIconView(channel: channel, size: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(channel.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                    Text(memberLine(channel))
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
            }
            Spacer(minLength: 8)
            if let channel = chat.selectedChannel {
                channelQuickActions(channel)
            }
            if !chat.typingUsers.isEmpty {
                ChatTypingIndicatorView(label: chat.typingSummary)
            }
        }
        .padding(.horizontal, CursorMacShellDesign.editorHorizontalPadding)
        .frame(height: CursorMacShellDesign.chatToolbarHeight)
        .background(CursorMacShellDesign.editorBoxBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorMacShellDesign.borderSubtle).frame(height: 1)
        }
    }

    private func memberLine(_ channel: ChatChannel) -> String {
        let n = chat.channelMemberCount(for: channel)
        return n == 1 ? "1 member" : "\(n) members"
    }

    @ViewBuilder
    private func channelQuickActions(_ channel: ChatChannel) -> some View {
        HStack(spacing: 4) {
            Button {
                chat.openWorkspaceSearch(scope: .channel)
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Search in channel")

            Button {
                chat.showPinnedPanel.toggle()
            } label: {
                Image(systemName: chat.showPinnedPanel ? "pin.fill" : "pin")
                    .font(.system(size: 12))
                    .foregroundStyle(chat.showPinnedPanel ? CursorTheme.accent : CursorTheme.foregroundMuted)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Pinned messages")

            Menu {
                ChatChannelActionsMenu(chat: chat, channel: channel)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("More channel actions")
        }
    }
}

extension ChatViewModel {
    var typingSummary: String {
        let names = typingUsers.map(\.displayName)
        if names.isEmpty { return "" }
        if names.count == 1 { return "\(names[0]) is typing" }
        if names.count == 2 { return "\(names[0]) and \(names[1]) are typing" }
        return "\(names[0]) and \(names.count - 1) others are typing"
    }
}
