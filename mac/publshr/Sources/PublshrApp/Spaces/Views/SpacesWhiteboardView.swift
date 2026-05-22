import SwiftUI

/// Whiteboard list for the active space. Full infinite canvas runs in Spaces Electron (`desktop/spaces`) or Phase 2 native host.
struct SpacesWhiteboardView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        HStack(spacing: 0) {
            boardList
                .frame(width: 220)
            Rectangle()
                .fill(CursorTheme.borderSubtle)
                .frame(width: 1)
            canvasPlaceholder
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(CursorMacShellDesign.editorColumnBackground)
    }

    private var boardList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task { await spaces.createWhiteboard() }
            } label: {
                Label("New whiteboard", systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.top, 12)

            if spaces.whiteboards.isEmpty {
                Text("No whiteboards yet. Create one to plan visually and link it to this space.")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .padding(.horizontal, 12)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(spaces.whiteboards) { board in
                            Button {
                                spaces.selectedWhiteboardId = board.id
                            } label: {
                                HStack {
                                    Image(systemName: "scribble.variable")
                                        .font(.system(size: 12))
                                    Text(board.name)
                                        .font(.system(size: 12, weight: spaces.selectedWhiteboardId == board.id ? .semibold : .regular))
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .foregroundStyle(
                                    spaces.selectedWhiteboardId == board.id
                                        ? CursorTheme.accent
                                        : CursorTheme.foreground
                                )
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            spaces.selectedWhiteboardId == board.id
                                                ? CursorTheme.tabActiveBackground
                                                : Color.clear
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var canvasPlaceholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 36))
                .foregroundStyle(CursorTheme.accent.opacity(0.85))
            Text(selectedTitle)
                .font(.system(size: 16, weight: .semibold))
            Text(
                "The whiteboard canvas matches the Electron renderer (tldraw + Supabase). Use Spaces in desktop/spaces for editing; macOS embeds the same web bundle in Phase 2 (see shared/spaces/PARITY.md)."
            )
            .font(.system(size: 12))
            .foregroundStyle(CursorTheme.foregroundMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var selectedTitle: String {
        if let id = spaces.selectedWhiteboardId,
           let board = spaces.whiteboards.first(where: { $0.id == id }) {
            return board.name
        }
        return "Whiteboard"
    }
}
