import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $model.selectedSection) { section in
                Label {
                    HStack {
                        Text(section.rawValue)
                        if section == .updates && model.updateAvailable {
                            Spacer()
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.orange)
                        }
                    }
                } icon: {
                    Image(systemName: section.icon)
                }
                .tag(section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch model.selectedSection {
            case .publisher:
                PublisherHomeView()
            case .updates:
                UpdatesPanelView()
            }
        }
        .frame(minWidth: 560, minHeight: 420)
    }
}

enum AppVersionLabel {
    static var current: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }
}
