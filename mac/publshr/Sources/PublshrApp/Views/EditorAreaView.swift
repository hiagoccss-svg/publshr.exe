import SwiftUI

struct EditorAreaView: View {
    @State private var activeTab = 0
    private let tabs = ["Welcome", "main.swift"]

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            editorContent
        }
        .background(CursorTheme.editorBackground)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    activeTab = index
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: index == 0 ? "house" : "swift")
                            .font(.system(size: 11))
                        Text(tab)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundStyle(activeTab == index ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                    .background(activeTab == index ? CursorTheme.tabActiveBackground : CursorTheme.tabInactiveBackground)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(height: CursorTheme.tabBarHeight)
        .background(CursorTheme.tabInactiveBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }

    private var editorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if activeTab == 0 {
                    welcomeContent
                } else {
                    codeSample
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(CursorTheme.editorBackground)
    }

    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to Publshr")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(CursorTheme.foreground)

            Text("Open a folder to start coding with AI assistance.")
                .font(.system(size: 14))
                .foregroundStyle(CursorTheme.foregroundMuted)

            HStack(spacing: 12) {
                actionChip("Open folder", icon: "folder")
                actionChip("Clone repo", icon: "arrow.down.circle")
            }
        }
    }

    private func actionChip(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 13))
        .foregroundStyle(CursorTheme.foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CursorTheme.sideBar)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CursorTheme.border, lineWidth: 1)
        )
    }

    private var codeSample: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sampleLines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .frame(width: 32, alignment: .trailing)
                    Text(line)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(colorForLine(line))
                }
                .padding(.vertical, 1)
            }
        }
    }

    private var sampleLines: [String] {
        [
            "import SwiftUI",
            "",
            "@main",
            "struct PublshrApp: App {",
            "    var body: some Scene {",
            "        WindowGroup {",
            "            ContentView()",
            "        }",
            "    }",
            "}",
        ]
    }

    private func colorForLine(_ line: String) -> Color {
        if line.hasPrefix("import") { return Color(hex: 0xC586C0) }
        if line.hasPrefix("@") || line.contains("struct") { return Color(hex: 0x4EC9B0) }
        if line.contains("var") || line.contains("some") { return Color(hex: 0x569CD6) }
        return CursorTheme.foreground
    }
}
