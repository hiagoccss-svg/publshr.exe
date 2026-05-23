import SwiftUI

/// Variable-height masonry columns (reference library card grid).
struct LibraryMasonryLayout: Layout {
    private static let masonryMinColumnWidth: CGFloat = 240
    private static let masonryMaxColumns = 4

    var columns: Int
    var spacing: CGFloat = LibraryGlassDesign.gridGutter

    init(columns: Int = 3, spacing: CGFloat = LibraryGlassDesign.gridGutter) {
        self.columns = max(1, columns)
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = Self.sanitizedWidth(proposal.width)
        guard width > 0, !subviews.isEmpty else { return .zero }
        let colCount = effectiveColumns(forWidth: width)
        let colWidth = columnWidth(totalWidth: width, columnCount: colCount)
        guard colWidth > 0 else { return .zero }
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
        let width = Self.sanitizedWidth(bounds.width)
        guard width > 0, !subviews.isEmpty else { return }
        let colCount = effectiveColumns(forWidth: width)
        let colWidth = columnWidth(totalWidth: width, columnCount: colCount)
        guard colWidth > 0 else { return }
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

    /// SwiftUI often proposes `.infinity` width inside `ScrollView`; never convert that to `Int`.
    private static func sanitizedWidth(_ width: CGFloat?) -> CGFloat {
        guard let width, width.isFinite, width > 0 else { return 0 }
        return min(width, 16_384)
    }

    private func columnWidth(totalWidth: CGFloat, columnCount: Int) -> CGFloat {
        guard columnCount > 0, totalWidth.isFinite else { return 0 }
        let gutters = spacing * CGFloat(max(0, columnCount - 1))
        let usable = totalWidth - gutters
        guard usable.isFinite, usable > 0 else { return 0 }
        return usable / CGFloat(columnCount)
    }

    private func effectiveColumns(forWidth width: CGFloat) -> Int {
        guard width.isFinite, width > 0 else { return 1 }
        let maxCols = min(Self.masonryMaxColumns, columns)
        let unit = Self.masonryMinColumnWidth + spacing
        guard unit.isFinite, unit > 0 else { return 1 }
        let raw = (width + spacing) / unit
        guard raw.isFinite, raw > 0 else { return 1 }
        let capped = min(raw, CGFloat(maxCols + 1))
        let fit = max(1, Int(capped.rounded(.down)))
        return min(maxCols, fit)
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
