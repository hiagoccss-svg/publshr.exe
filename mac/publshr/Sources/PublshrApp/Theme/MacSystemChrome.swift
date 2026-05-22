import SwiftUI

/// Soft macOS-native surfaces — match column chrome, avoid boxed “web app” fields and sheets.
enum MacSystemChrome {
    static let fieldCornerRadius: CGFloat = 8
    static let fieldFontSize: CGFloat = 13
    static let sheetCornerRadius: CGFloat = 10
    static let sheetPadding: CGFloat = 16

    /// Inline field on editor/submenu columns (no white card or hairline box).
    static func fieldBackground(for colorScheme: ColorScheme = .light) -> Color {
        CursorMacShellDesign.editorColumnBackground
    }

    static func submenuFieldBackground() -> Color {
        CursorMacShellDesign.columnChromeBackground.opacity(0.35)
    }

    static var fieldHoverFill: Color {
        Color.black.opacity(0.04)
    }

    static var toolbarHoverFill: Color {
        Color.black.opacity(0.06)
    }

    static var toolbarPressedFill: Color {
        Color.black.opacity(0.09)
    }
}

// MARK: - Inline text field (composer, search bands)

struct MacInlineTextFieldStyle: ViewModifier {
    var background: Color
    var cornerRadius: CGFloat = MacSystemChrome.fieldCornerRadius
    var horizontalPadding: CGFloat = 12
    var verticalPadding: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
            )
    }
}

extension View {
    func macInlineTextField(
        background: Color = MacSystemChrome.fieldBackground(),
        cornerRadius: CGFloat = MacSystemChrome.fieldCornerRadius
    ) -> some View {
        modifier(MacInlineTextFieldStyle(background: background, cornerRadius: cornerRadius))
    }

    /// Floating panel styled like AppKit sheets (material, soft edge, no harsh stroke).
    func macNativeSheetFrame(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil) -> some View {
        frame(minWidth: minWidth, idealWidth: idealWidth, minHeight: minHeight, idealHeight: idealHeight)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: MacSystemChrome.sheetCornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 18, y: 8)
    }

    /// System sheet chrome (macOS 14+): material background, no default web-style padding.
    func macNativeSheetPresentation() -> some View {
        presentationBackground(.regularMaterial)
            .presentationCornerRadius(MacSystemChrome.sheetCornerRadius)
    }
}
