import SwiftUI

struct IncomingCallRingView: View {
    let invite: IncomingCallInvite
    @EnvironmentObject private var calls: CallSignalingService
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var auth: AuthViewModel

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(CursorTheme.accent.opacity(0.35), lineWidth: 3)
                        .frame(width: 72, height: 72)
                        .scaleEffect(pulse ? 1.08 : 1)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                    ChatProfileAvatar(
                        profile: chat.profile(for: invite.callerId),
                        displayName: invite.callerName,
                        size: 56
                    )
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(invite.isVideo ? "Incoming video" : "Incoming voice")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CursorTheme.foregroundDim)
                    Text(chat.displayName(for: invite.callerId))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                    Text(invite.channelTitle)
                        .font(.system(size: 12))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .lineLimit(1)
                    Label(invite.scope.label, systemImage: invite.scope.icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CursorTheme.accent)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                Button {
                    Task { await calls.declineIncomingCall() }
                } label: {
                    Label("Decline", systemImage: "phone.down.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    Task { await calls.acceptIncomingCall(chat: chat, auth: auth) }
                } label: {
                    Label("Accept", systemImage: "phone.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CursorTheme.accent)
            }
        }
        .padding(18)
        .glassPanel(cornerRadius: 18, opacity: 0.78)
        .onAppear { pulse = true }
    }
}
