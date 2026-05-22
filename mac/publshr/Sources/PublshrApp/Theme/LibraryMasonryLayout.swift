import SwiftUI

/// Variable-height masonry columns (reference library card grid).
struct LibraryMasonryLayout: Layout {
    var columns: Int
    var spacing: CGFloat = LibraryGlassDesign.gridGutter

    init(columns: Int = 3, spacing: CGFloat = LibraryGlassDesign.gridGutter) {
        self.columns = max(1, columns)
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        guard width > 0, !subviews.isEmpty else { return .zero }
        let colCount = effectiveColumns(forWidth: width)
        let colWidth = (width - spacing * CGFloat(colCount - 1)) / CGFloat(colCount)
        var columnHeights = Array(repeating: CGFloat(0), count: colCount)
        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: colWidth, height: nil))
            let shortest = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columnHeights[shortest] += size.height + spacing
        }
        let maxH = (columnHeights.max() ?? 0) - spacing
        return CGSize(width: width, height: max(0, maxH))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let colCount = effectiveColumns(forWidth: bounds.width)
        let colWidth = (bounds.width - spacing * CGFloat(colCount - 1)) / CGFloat(colCount)
        var columnHeights = Array(repeating: CGFloat(0), count: colCount)
        var columnX = Array(repeating: CGFloat(0), count: colCount)
        for i in 0..<colCount {
            columnX[i] = bounds.minX + CGFloat(i) * (colWidth + spacing)
        }
        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: colWidth, height: nil))
            let col = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let x = columnX[col]
            let y = bounds.minY + columnHeights[col]
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: colWidth, height: size.height))
            columnHeights[col] += size.height + spacing
        }
    }

    private func effectiveColumns(forWidth width: CGFloat) -> Int {
        let maxCols = LibraryGlassDesign.masonryMaxColumns
        let minW = LibraryGlassDesign.masonryMinColumnWidth
        let fit = max(1, Int((width + spacing) / (minW + spacing)))
        return min(maxCols, fit, columns)
    }
}

struct LibraryMasonryGrid<Content: View>: View {
    var columns: Int
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(
        columns: Int = 3,
        spacing: CGFloat = LibraryGlassDesign.gridGutter,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LibraryMasonryLayout(columns: columns, spacing: spacing) {
            content()
        }
    }
}
