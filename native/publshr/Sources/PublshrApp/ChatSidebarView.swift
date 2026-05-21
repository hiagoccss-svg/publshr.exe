import SwiftUI
import PublshrCore

struct ChatSidebarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Chat")
                    .font(.headline)
                Spacer()
                Button(action: model.createChannel) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            TextField("Search channels", text: $model.sidebarSearch)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            Text("CHANNELS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(PublshrTheme.textSecondary)
                .padding(.horizontal, 12)

            List(selection: $model.selectedChannelID) {
                Section {
                    ForEach(model.filteredChannels.filter { !$0.isDM }) { channel in
                        channelRow(channel, prefix: "#")
                    }
                }
                Section("Direct messages") {
                    ForEach(model.filteredChannels.filter { $0.isDM }) { channel in
                        channelRow(channel, prefix: "")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func channelRow(_ channel: ChatChannel, prefix: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(PublshrTheme.accent.opacity(0.5))
                .frame(width: 8, height: 8)
            Text("\(prefix)\(channel.name)")
                .lineLimit(1)
        }
        .tag(channel.id)
    }
}
