import SwiftUI

struct ChatMentionPickerView: View {
    @ObservedObject var chat: ChatViewModel
    let query: String
    var onPick: (String) -> Void

    private var showHere: Bool {
        query.isEmpty || "here".hasPrefix(query.lowercased())
    }

    private var showChannel: Bool {
        query.isEmpty || "channel".hasPrefix(query.lowercased())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showHere {
                mentionRow(handle: "here", title: "@here", subtitle: "Notify active members")
            }
            if showChannel {
                mentionRow(handle: "channel", title: "@channel", subtitle: "Notify everyone in channel")
            }
            ForEach(chat.mentionCandidates(matching: query), id: \.id) { profile in
                let handle = chat.mentionHandle(for: profile)
                Button {
                    onPick(handle)
                } label: {
                    HStack(spacing: 8) {
                        ChatProfileAvatar(
                            profile: profile,
                            displayName: profile.displayName ?? profile.email,
                            size: 24,
                            presence: chat.presence(for: profile.id)
                        )
                        VStack(alignment: .leading, spacing: 1) {
                            Text(profile.displayName ?? profile.email)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CursorTheme.foreground)
                            Text("@\(handle)")
                                .font(.system(size: 10))
                                .foregroundStyle(CursorTheme.foregroundDim)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(CursorTheme.panelBackground)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(CursorTheme.border.opacity(0.35), lineWidth: 1)
        )
    }

    private func mentionRow(handle: String, title: String, subtitle: String) -> some View {
        Button {
            onPick(handle)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: handle == "here" ? "bolt.fill" : "number")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.accent)
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CursorTheme.foreground)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
