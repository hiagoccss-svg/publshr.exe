import SwiftUI

/// ClickUp-style location header: Space › Folder › List.
struct SpacesBreadcrumbBar: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        HStack(spacing: SpacesClickUpDesign.chromeItemSpacing) {
            ForEach(Array(spaces.breadcrumbItems.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
                breadcrumbButton(item)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, SpacesClickUpDesign.chromeHorizontalPadding)
        .frame(height: SpacesClickUpDesign.breadcrumbBarHeight)
        .background(CursorTheme.editorBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
        }
    }

    @ViewBuilder
    private func breadcrumbButton(_ item: SpacesBreadcrumbItem) -> some View {
        Button {
            Task { await spaces.navigateBreadcrumb(item) }
        } label: {
            HStack(spacing: 5) {
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundStyle(item.isLast ? CursorTheme.accent : CursorTheme.foregroundMuted)
                }
                Text(item.title)
                    .font(SpacesClickUpDesign.breadcrumbFont)
                    .foregroundStyle(item.isLast ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .disabled(item.isLast)
    }
}
