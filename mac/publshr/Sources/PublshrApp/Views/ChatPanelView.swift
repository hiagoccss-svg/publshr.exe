import SwiftUI

/// Legacy AI assistant panel (replaced by `EnterpriseChatView` in the main IDE layout).
struct ChatPanelView: View {
    @Binding var input: String
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Chat")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CursorTheme.foreground)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(CursorTheme.panelBackground)
            .overlay(alignment: .bottom) {
                Rectangle().fill(CursorTheme.border).frame(height: 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    chatBubble(
                        role: "You",
                        text: "How do I connect my Supabase account?",
                        isUser: true
                    )
                    chatBubble(
                        role: "Cursor",
                        text: "You're signed in as \(auth.profile?.displayName ?? auth.profile?.email ?? "user"). Your profile is synced from Supabase automatically after signup.",
                        isUser: false
                    )
                }
                .padding(12)
            }
            .background(CursorTheme.chatBackground)

            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Ask anything, @ for context, / for commands", text: $input, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(CursorTheme.foreground)
                        .lineLimit(1...6)
                        .padding(10)
                        .background(CursorTheme.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(CursorTheme.borderSubtle, lineWidth: 1)
                        )

                    Button {} label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(input.isEmpty ? CursorTheme.foregroundDim : CursorTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(input.isEmpty)
                }

                HStack(spacing: 8) {
                    modelChip("Agent")
                    modelChip("Auto")
                    Spacer()
                }
            }
            .padding(12)
            .background(CursorTheme.panelBackground)
            .overlay(alignment: .top) {
                Rectangle().fill(CursorTheme.border).frame(height: 1)
            }
        }
        .background(CursorTheme.panelBackground)
    }

    private func chatBubble(role: String, text: String, isUser: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(role)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foreground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(isUser ? CursorTheme.sideBar : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func modelChip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 11))
            .foregroundStyle(CursorTheme.foregroundMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(CursorTheme.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
