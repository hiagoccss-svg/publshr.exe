import SwiftUI
import PublshrCore

struct ChatMainView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let ch = model.selectedChannel {
                    Text(ch.isDM ? ch.name : "#\(ch.name)")
                        .font(.title3.bold())
                } else {
                    Text("Select a channel")
                        .font(.title3)
                        .foregroundStyle(PublshrTheme.textSecondary)
                }
                Spacer()
                Text(model.statusMessage)
                    .font(.caption)
                    .foregroundStyle(PublshrTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(PublshrTheme.sidebar)

            Divider().overlay(PublshrTheme.border)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(model.channelMessages) { msg in
                            messageRow(msg)
                                .id(msg.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: model.channelMessages.count) { _, _ in
                    if let last = model.channelMessages.last?.id {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }

            Divider().overlay(PublshrTheme.border)

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Message #\(model.selectedChannel?.name ?? "channel")", text: $model.chatInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .lineLimit(1...6)
                    .onSubmit { model.sendMessage() }

                Button("Send", action: model.sendMessage)
                    .buttonStyle(.borderedProminent)
                    .tint(PublshrTheme.accent)
                    .disabled(model.chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(PublshrTheme.sidebar)
        }
    }

    private func messageRow(_ msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(PublshrTheme.accent.opacity(0.7))
                .frame(width: 32, height: 32)
                .overlay(Text(String(msg.author.prefix(1))).font(.caption.bold()).foregroundStyle(.white))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(msg.author).font(.subheadline.bold())
                    Text(msg.sentAt, style: .time).font(.caption2).foregroundStyle(PublshrTheme.textSecondary)
                }
                Text(msg.body)
                    .font(.body)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
        }
    }
}
