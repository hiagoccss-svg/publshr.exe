import AppKit
import SwiftUI

/// In-app Publshr mark — same asset as Dock icon (`icon.png` from repo-root source of truth).
enum PublshrBrandLogo {
    static var nsImage: NSImage? {
        if let url = Bundle.main.url(forResource: "icon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return nil
    }

    static var hasImage: Bool { nsImage != nil }
}

struct PublshrBrandLogoView: View {
    var size: CGFloat = 24
    var cornerRadius: CGFloat = 6

    var body: some View {
        Group {
            if let image = PublshrBrandLogo.nsImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: size * 0.72, weight: .medium))
                    .foregroundStyle(CursorTheme.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
