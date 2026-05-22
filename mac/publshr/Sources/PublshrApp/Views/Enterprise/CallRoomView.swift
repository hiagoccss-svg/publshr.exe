import SwiftUI

/// In-call UI inside the glass call window.
struct CallRoomView: View {
    @EnvironmentObject private var calls: CallSignalingService
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.35)
            participantGrid
            Divider().opacity(0.35)
            controls
        }
        .glassPanel(cornerRadius: 14, opacity: 0.82)
        .onChange(of: calls.isMuted) { _, _ in
            Task { await calls.onMuteChanged() }
        }
        .onChange(of: calls.isVideoEnabled) { _, _ in
            Task { await calls.onMuteChanged() }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Label(calls.callScope.label, systemImage: calls.callScope.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CursorTheme.accent)
                Spacer()
                Text(calls.activeRoom?.kind == "video" ? "Video" : "Voice")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.5))
                    .clipShape(Capsule())
            }
            Text(calls.activeRoom?.title ?? "Call")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            Text(calls.mediaStatus)
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .multilineTextAlignment(.center)
            if let code = calls.localRoomCode {
                Text("Room \(code) · up to 20 on LAN")
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            if let hint = calls.localJoinHint {
                Text(hint)
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(14)
    }

    private var participantGrid: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(calls.participants.filter(\.isActive)) { p in
                    HStack(spacing: 10) {
                        ChatProfileAvatar(
                            profile: chat.profile(for: p.userId),
                            displayName: chat.displayName(for: p.userId),
                            size: 40
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(chat.displayName(for: p.userId))
                                .font(.system(size: 13, weight: .medium))
                            HStack(spacing: 8) {
                                if p.isMuted {
                                    Label("Muted", systemImage: "mic.slash").font(.system(size: 10))
                                }
                                if p.isVideoEnabled {
                                    Label("Video", systemImage: "video").font(.system(size: 10))
                                }
                            }
                            .foregroundStyle(CursorTheme.foregroundDim)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 280)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            callControlButton(
                calls.isMuted ? "mic.slash.fill" : "mic.fill",
                title: calls.isMuted ? "Unmute" : "Mute",
                tint: CursorTheme.foreground
            ) {
                calls.isMuted.toggle()
            }
            callControlButton(
                calls.isVideoEnabled ? "video.fill" : "video",
                title: "Video",
                tint: CursorTheme.foreground
            ) {
                calls.isVideoEnabled.toggle()
            }
            Spacer()
            Button("Leave") {
                Task { await calls.leaveCall() }
            }
            .buttonStyle(.bordered)
            Button("End") {
                Task { await calls.endCall() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(auth.profile?.id != calls.activeRoom?.createdBy)
        }
        .padding(14)
    }

    private func callControlButton(
        _ symbol: String,
        title: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundStyle(tint)
            .frame(width: 56, height: 48)
            .background(Color.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
