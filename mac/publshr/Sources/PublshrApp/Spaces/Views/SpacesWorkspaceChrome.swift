import SwiftUI

/// Spaces workspace chrome: breadcrumbs + views bar (ClickUp location header + views).
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
                SpacesBreadcrumbBar(spaces: spaces)
                SpacesViewsBar(spaces: spaces)
            }
            content()
        }
        .background(Color.clear)
    }
}
