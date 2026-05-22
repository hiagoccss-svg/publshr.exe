import SwiftUI

/// In-call UI — native macOS panel with live participant list (Supabase signaling).
struct CallRoomView: View {
    @EnvironmentObject private var calls: CallSignalingService
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            participantGrid
            Divider()
            controls
        }
        .frame(width: 360, height: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(calls.activeRoom?.title ?? "Call")
                .font(.headline)
            Text(calls.mediaStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var participantGrid: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(calls.participants.filter(\.isActive)) { p in
                    HStack(spacing: 10) {
                        ChatProfileAvatar(
                            profile: chat.profile(for: p.userId),
                            displayName: chat.displayName(for: p.userId),
                            size: 36
                        )
                        VStack(alignment: .leading) {
                            Text(chat.displayName(for: p.userId))
                                .font(.subheadline.weight(.medium))
                            HStack(spacing: 6) {
                                if p.isMuted {
                                    Image(systemName: "mic.slash").font(.caption)
                                }
                                if p.isVideoEnabled {
                                    Image(systemName: "video").font(.caption)
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                calls.isMuted.toggle()
            } label: {
                Label(calls.isMuted ? "Unmute" : "Mute", systemImage: calls.isMuted ? "mic.slash.fill" : "mic.fill")
            }
            Button {
                calls.isVideoEnabled.toggle()
            } label: {
                Label("Video", systemImage: calls.isVideoEnabled ? "video.fill" : "video")
            }
            Spacer()
            Button("Leave") {
                Task { await calls.leaveCall() }
            }
            Button("End for all", role: .destructive) {
                Task { await calls.endCall() }
            }
            .disabled(auth.profile?.id != calls.activeRoom?.createdBy)
        }
        .padding()
    }
}
