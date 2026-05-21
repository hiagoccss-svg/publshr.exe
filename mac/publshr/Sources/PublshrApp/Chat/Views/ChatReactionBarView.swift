import SwiftUI

struct ChatReactionBarView: View {
    let summaries: [ChatReactionSummary]
    let onToggle: (String) -> Void

    var body: some View {
        if !summaries.isEmpty {
            HStack(spacing: 6) {
                ForEach(summaries, id: \.emoji) { summary in
                    Button {
                        onToggle(summary.emoji)
                    } label: {
                        HStack(spacing: 4) {
                            Text(summary.emoji)
                            if summary.count > 1 {
                                Text("\(summary.count)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(CursorTheme.foregroundMuted)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            summary.includesMe
                                ? CursorTheme.accent.opacity(0.25)
                                : CursorTheme.inputBackground
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ChatQuickReactionPicker: View {
    let onPick: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ChatQuickReaction.allCases, id: \.rawValue) { reaction in
                Button(reaction.rawValue) { onPick(reaction.rawValue) }
                    .buttonStyle(.plain)
                    .font(.system(size: 16))
            }
        }
    }
}
