import SwiftUI
import AppKit

struct ChatAISheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    periodSection
                    quickActionsSection
                    resultSection
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(width: 520, height: 560)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Chat recap")
                    .font(.system(size: 15, weight: .semibold))
                Text(chat.selectedChannel?.displayTitle ?? "Select a channel")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .lineLimit(1)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Date range")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CursorTheme.foregroundDim)
                    DatePicker(
                        "",
                        selection: $chat.summaryPeriodStart,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.field)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CursorTheme.foregroundDim)
                    DatePicker(
                        "",
                        selection: $chat.summaryPeriodEnd,
                        in: chat.summaryPeriodStart...,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.field)
                }
            }

            HStack(spacing: 8) {
                presetButton("Last 7 days", daysBack: 7)
                presetButton("Last 30 days", daysBack: 30)
                presetButton("Today", daysBack: 0, todayOnly: true)
            }

            Button {
                Task { await chat.runPeriodScriptSummary() }
            } label: {
                Label("Generate script recap", systemImage: "doc.text.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(CursorTheme.accent)
            .disabled(chat.selectedChannel == nil || chat.isAILoading)

            if let err = chat.summaryPeriodError, !err.isEmpty {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.error)
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick actions")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            HStack(spacing: 8) {
                Button("Summarize visible") {
                    Task { await chat.runAISummary(unreadOnly: false) }
                }
                .buttonStyle(.bordered)
                .disabled(chat.selectedChannel == nil)

                Button("Suggest reply") { chat.applySuggestedReply() }
                    .buttonStyle(.bordered)
                    .disabled(chat.selectedChannel == nil)
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if chat.isAILoading {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Building script from messages…")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
        } else if let result = chat.aiResult {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(result.title)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Button("Copy") { copyRecap(result.body) }
                        .buttonStyle(.borderless)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(result.body)
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foreground)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !result.actionItems.isEmpty {
                    Text("Follow-ups")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .padding(.top, 4)
                    ForEach(result.actionItems, id: \.self) { item in
                        Text("• \(item)")
                            .font(.system(size: 11))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(CursorTheme.panelBackground.opacity(0.6))
            )
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    private func presetButton(_ label: String, daysBack: Int, todayOnly: Bool = false) -> some View {
        Button(label) {
            let cal = Calendar.current
            let end = cal.startOfDay(for: Date())
            chat.summaryPeriodEnd = end
            if todayOnly {
                chat.summaryPeriodStart = end
            } else {
                chat.summaryPeriodStart = cal.date(byAdding: .day, value: -daysBack, to: end) ?? end
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func copyRecap(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
