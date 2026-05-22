import SwiftUI

/// Lightweight notifications drawer from the titlebar bell control.
struct TitlebarNotificationsPanelView: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var isPresented: Bool

    private var unreadChannels: [(ChatChannel, Int)] {
        let all = chat.channels + chat.directMessages
        return all.compactMap { ch -> (ChatChannel, Int)? in
            let n = chat.unreadCount(for: ch.id)
            return n > 0 ? (ch, n) : nil
        }
        .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notifications")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Done") { isPresented = false }
                    .buttonStyle(.plain)
            }

            if unreadChannels.isEmpty {
                Text("You're all caught up.")
                    .font(.system(size: 13))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(unreadChannels, id: \.0.id) { channel, count in
                            Button {
                                chat.selectChannel(channel)
                                isPresented = false
                            } label: {
                                HStack {
                                    Text(channel.displayTitle)
                                        .font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    Text("\(count)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(CursorTheme.accent))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.white.opacity(0.5))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
