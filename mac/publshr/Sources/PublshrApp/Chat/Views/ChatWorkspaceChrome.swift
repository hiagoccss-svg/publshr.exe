import SwiftUI

/// Chat content wrapper — chrome lives in `LibraryShellHeaderView`.
struct ChatWorkspaceChrome<Content: View>: View {
    var topInset: CGFloat = 0
    var embedInPopOut: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            if !embedInPopOut, topInset > 0 {
                Color.clear.frame(height: topInset)
            }
            content()
        }
        .background(Color.clear)
    }
}
