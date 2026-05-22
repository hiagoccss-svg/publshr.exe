import SwiftUI

struct TitlebarCommandPaletteItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let systemImage: String
    let shortcut: String?
    let isEnabled: Bool
    let action: () -> Void
}

/// Cursor / VS Code style command palette — driven by the unified titlebar.
struct TitlebarCommandPaletteView: View {
    let items: [TitlebarCommandPaletteItem]
    @Binding var isPresented: Bool
    @State private var query = ""
    @FocusState private var focused: Bool

    private var filtered: [TitlebarCommandPaletteItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items.filter(\.isEnabled) + items.filter { !$0.isEnabled } }
        return items.filter {
            $0.title.lowercased().contains(q)
                || ($0.subtitle?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "command")
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                TextField("Type a command…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($focused)
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(14)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filtered) { item in
                        Button {
                            guard item.isEnabled else { return }
                            isPresented = false
                            item.action()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: item.systemImage)
                                    .frame(width: 18)
                                    .foregroundStyle(item.isEnabled ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.title)
                                        .font(.system(size: 13, weight: .medium))
                                    if let subtitle = item.subtitle {
                                        Text(subtitle)
                                            .font(.system(size: 11))
                                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                                    }
                                }
                                Spacer()
                                if let shortcut = item.shortcut {
                                    Text(shortcut)
                                        .font(.system(size: 11))
                                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.primary.opacity(0.04))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!item.isEnabled)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 320)
        }
        .frame(width: 480)
        .background(.regularMaterial)
        .onAppear {
            query = ""
            focused = true
        }
    }
}
