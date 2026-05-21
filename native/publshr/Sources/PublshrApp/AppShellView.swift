import SwiftUI

struct AppShellView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack(spacing: 0) {
            IconRailView()
                .frame(width: PublshrTheme.railWidth)

            Rectangle()
                .fill(PublshrTheme.border)
                .frame(width: 1)

            secondarySidebar

            Rectangle()
                .fill(PublshrTheme.border)
                .frame(width: 1)

            mainPanel
        }
        .background(PublshrTheme.bg)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var secondarySidebar: some View {
        Group {
            switch model.section {
            case .chat:
                ChatSidebarView()
            case .spaces:
                SpacesSidebarView()
            }
        }
        .frame(width: PublshrTheme.sidebarWidth)
        .background(PublshrTheme.sidebar)
    }

    @ViewBuilder
    private var mainPanel: some View {
        Group {
            switch model.section {
            case .chat:
                ChatMainView()
            case .spaces:
                SpacesMainView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PublshrTheme.panel)
    }
}

struct IconRailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text("P")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(PublshrTheme.accent)
                Text("v\(AppVersionLabel.current)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(PublshrTheme.textSecondary)
            }
            .padding(.top, 10)

            ForEach(MainSection.allCases) { item in
                Button {
                    model.section = item
                } label: {
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .frame(width: 36, height: 36)
                        .background(model.section == item ? PublshrTheme.accent.opacity(0.25) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .foregroundStyle(model.section == item ? PublshrTheme.accent : PublshrTheme.textSecondary)
                .help(item.rawValue)
            }

            Spacer()

            Button { openSettings() } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .foregroundStyle(PublshrTheme.textSecondary)
            .padding(.bottom, 12)
        }
        .frame(maxHeight: .infinity)
        .background(PublshrTheme.sidebar)
    }
}
