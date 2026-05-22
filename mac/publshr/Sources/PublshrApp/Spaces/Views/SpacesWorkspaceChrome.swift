import SwiftUI

/// Spaces content wrapper — tabs and toolbar live in `WorkspaceHeaderView`.
struct SpacesWorkspaceChrome<Content: View>: View {
    @ObservedObject var spaces: SpacesViewModel
    var topInset: CGFloat = 0
    var embedInPopOut: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            if !embedInPopOut, topInset > 0 {
                Color.clear.frame(height: topInset)
            }
            if spaces.selectedSpaceId != nil, !embedInPopOut {
                SpacesHierarchyBar(spaces: spaces)
            }
            content()
        }
        .background(CursorTheme.editorBackground)
    }
}
