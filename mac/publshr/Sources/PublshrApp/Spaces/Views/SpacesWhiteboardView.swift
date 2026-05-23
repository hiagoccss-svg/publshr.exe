import SwiftUI

/// Whiteboard list + embedded tldraw canvas inside Publshr.app (no separate Electron window).
struct SpacesWhiteboardView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var spaces: SpacesViewModel
    @State private var webError: String?

    var body: some View {
        HStack(spacing: 0) {
            boardList
                .frame(width: 220)
            Rectangle()
                .fill(CursorTheme.borderSubtle)
                .frame(width: 1)
            canvasArea
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
                                webError = nil
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
    private var canvasArea: some View {
        if let boardId = spaces.selectedWhiteboardId, let spaceId = spaces.selectedSpaceId {
            MacWebModuleHost(
                config: MacWebModuleConfig(
                    module: .whiteboard,
                    spaceId: spaceId,
                    whiteboardId: boardId,
                    workspaceId: auth.selectedWorkspace?.id,
                    accessToken: auth.session?.accessToken,
                    userId: auth.session?.user.id
                ),
                onLoadError: { webError = $0 }
            )
            .overlay(alignment: .bottomLeading) {
                if let webError {
                    Text(webError)
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.error)
                        .padding(10)
                        .background(CursorTheme.panelBackground.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(12)
                }
            }
        } else {
            VStack(spacing: 14) {
                Image(systemName: "scribble.variable")
                    .font(.system(size: 36))
                    .foregroundStyle(CursorTheme.accent.opacity(0.85))
                Text("Select or create a whiteboard")
                    .font(.system(size: 16, weight: .semibold))
                Text("Canvas runs inside Publshr.app with live Supabase sync.")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
