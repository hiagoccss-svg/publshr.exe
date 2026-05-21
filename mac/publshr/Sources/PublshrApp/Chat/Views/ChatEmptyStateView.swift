import SwiftUI

struct ChatEmptyStateView: View {
    let onNewMessage: () -> Void
    let onCreateChannel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(CursorTheme.foregroundDim)
            Text("No messages yet.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)
            Text("Start a conversation with your team.")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button("New Message", action: onNewMessage)
                    .buttonStyle(ChatPrimaryButtonStyle())
                Button("Create Channel", action: onCreateChannel)
                    .buttonStyle(ChatSecondaryButtonStyle())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

struct ChatPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(CursorTheme.buttonBackground.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct ChatSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(CursorTheme.foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(CursorTheme.inputBackground.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(CursorTheme.borderSubtle, lineWidth: 1)
            )
    }
}
