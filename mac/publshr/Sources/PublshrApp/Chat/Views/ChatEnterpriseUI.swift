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
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(CursorTheme.borderSubtle, lineWidth: 1))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

/// Join banner when another call is live on this channel.
struct JoinActiveCallBanner: View {
    let summary: LiveCallSummary
    let onJoin: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: summary.isVideo ? "video.fill" : "phone.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Call in progress")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(summary.scope.label) · \(summary.participantCount) in call")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Button("Join", action: onJoin)
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(CursorTheme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [CursorTheme.accent, CursorTheme.accentHover],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

/// Channel strip under workspace header — members, typing, join call.
struct ChatChannelStatusBar: View {
    @EnvironmentObject private var calls: CallSignalingService
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            if let channel = chat.selectedChannel,
               let live = calls.liveCall(for: channel.id),
               !calls.isInCall(on: channel.id) {
                JoinActiveCallBanner(summary: live) {
                    Task { await calls.joinActiveCall(for: channel.id) }
                }
            }
            HStack(spacing: 12) {
                if let channel = chat.selectedChannel {
                    Text(channel.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                    Text(memberLine(channel))
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
                Spacer()
                if !chat.typingUsers.isEmpty {
                    ChatTypingIndicatorView(label: chat.typingSummary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
        }
    }

    private func memberLine(_ channel: ChatChannel) -> String {
        let n = chat.channelMemberCount(for: channel)
        return n == 1 ? "1 member" : "\(n) members"
    }
}

/// Compact pill on sidebar rows when a call is live.
struct LiveCallChannelBadge: View {
    let summary: LiveCallSummary

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
            Text("Live")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.green.opacity(0.9))
        .clipShape(Capsule())
        .help("\(summary.participantCount) in \(summary.scope.label.lowercased()) call — click channel menu to join")
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
