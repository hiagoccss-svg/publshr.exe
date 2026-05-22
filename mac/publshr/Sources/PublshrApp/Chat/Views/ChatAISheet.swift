import SwiftUI

struct ChatAISheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Assistant")
                .font(.headline)

            HStack(spacing: 10) {
                Button("Summarize channel") {
                    Task { await chat.runAISummary(unreadOnly: false) }
                }
                Button("Summarize thread") {
                    Task { await chat.runAISummary(unreadOnly: false) }
                }
                .disabled(!chat.showThreadPanel)
                Button("Suggest reply") { chat.applySuggestedReply() }
            }

            if chat.isAILoading {
                ProgressView("Analyzing…")
            } else if let result = chat.aiResult {
                Text(result.title)
                    .font(.subheadline.weight(.semibold))
                Text(result.body)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                if !result.actionItems.isEmpty {
                    Text("Action items")
                        .font(.caption.weight(.semibold))
                    ForEach(result.actionItems, id: \.self) { item in
                        Text("• \(item)")
                            .font(.caption)
                    }
                }
            }

            Spacer()
            Button("Close") { dismiss() }
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(MacSystemChrome.sheetPadding)
        .frame(width: 440, height: 400)
        .macNativeSheetPresentation()
    }
}
