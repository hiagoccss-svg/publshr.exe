import SwiftUI
import AppKit

/// Native macOS surfaces for Spaces — AppKit colors, not web-style bordered cards.
enum SpacesNativeDesign {
    static var workspaceBackground: Color {
        Color(nsColor: .textBackgroundColor)
    }

    static var columnBackground: Color {
        Color(nsColor: .controlBackgroundColor).opacity(0.55)
    }

    static var cardBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }

    static var cardSelected: Color {
        Color.accentColor.opacity(0.12)
    }

    static var separator: Color {
        Color(nsColor: .separatorColor).opacity(0.45)
    }

    static let columnWidth: CGFloat = 272
    static let inspectorWidth: CGFloat = 340
    static let sidebarMinWidth: CGFloat = 220

    static func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.4)
    }
}

/// macOS segmented view switcher (Overview / List / Board).
struct SpacesViewModePicker: View {
    @Binding var selection: SpacesViewModel.TaskViewMode

    var body: some View {
        Picker("View", selection: $selection) {
            ForEach(SpacesViewModel.TaskViewMode.allCases) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 220)
    }
}

/// Inspector section block — reads like System Settings / Finder inspector.
struct SpacesInspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SpacesNativeDesign.sectionHeader(title)
            content
        }
    }
}
