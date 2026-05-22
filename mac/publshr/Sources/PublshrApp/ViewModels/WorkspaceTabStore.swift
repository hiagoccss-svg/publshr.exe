import Foundation
import SwiftUI

@MainActor
final class WorkspaceTabStore: ObservableObject {
    @Published private(set) var tabs: [WorkspaceTab] = []
    @Published var selectedTabId: String?
    @AppStorage("publshr.sidebarExpanded") var sidebarExpanded = true
    @Published var detachDragTabId: String?

    private var suppressSelectionSync = false

    // MARK: - Tab lifecycle

    func ensureDefaultTabs(module: AppModule) {
        removeSettingsTabs()
        if tabs.isEmpty {
            let seed = module == .settings ? AppModule.chat : module
            openTab(.app(seed), activate: true)
        }
    }

    func removeSettingsTabs() {
        let hadSettings = tabs.contains { if case .app(.settings) = $0.kind { return true }; return false }
        guard hadSettings else { return }
        tabs.removeAll { if case .app(.settings) = $0.kind { return true }; return false }
        if tabs.isEmpty {
            openTab(.app(.chat), activate: true)
            return
        }
        if selectedTabId == nil || !tabs.contains(where: { $0.id == selectedTabId }) {
            selectedTabId = tabs.first?.id
        }
    }

    @discardableResult
    func openTab(_ tab: WorkspaceTab, activate: Bool = true) -> WorkspaceTab {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            var existing = tabs[index]
            existing.title = tab.title
            existing.subtitle = tab.subtitle
            existing.iconSystemName = tab.iconSystemName
            existing.isPinned = tab.isPinned
            tabs[index] = existing
            if activate { selectedTabId = tab.id }
            return existing
        }
        tabs.append(tab)
        if activate { selectedTabId = tab.id }
        return tab
    }

    func closeTab(id: String) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let closingPinnedOnly = tabs.count == 1
        if closingPinnedOnly { return }

        tabs.remove(at: index)
        if selectedTabId == id {
            let nextIndex = min(index, tabs.count - 1)
            selectedTabId = tabs.indices.contains(nextIndex) ? tabs[nextIndex].id : tabs.last?.id
        }
    }

    func selectTab(id: String) {
        guard tabs.contains(where: { $0.id == id }) else { return }
        selectedTabId = id
    }

    func moveTab(from source: Int, to destination: Int) {
        guard source != destination,
              tabs.indices.contains(source),
              tabs.indices.contains(destination) else { return }
        let item = tabs.remove(at: source)
        tabs.insert(item, at: destination)
    }

    func reorderTab(draggedId: String, before targetId: String) {
        guard draggedId != targetId,
              let from = tabs.firstIndex(where: { $0.id == draggedId }),
              let to = tabs.firstIndex(where: { $0.id == targetId }) else { return }
        moveTab(from: from, to: to)
    }

    var selectedTab: WorkspaceTab? {
        guard let selectedTabId else { return nil }
        return tabs.first { $0.id == selectedTabId }
    }

    // MARK: - Sync with app state

    func openFromChannel(_ channel: ChatChannel, activate: Bool = true) {
        openTab(.chat(channel), activate: activate)
    }

    func openFromSpace(_ space: SpaceRecord, activate: Bool = true) {
        openTab(.space(space), activate: activate)
    }

    func openFromModule(_ module: AppModule, activate: Bool = true) {
        guard module != .settings else { return }
        openTab(.app(module), activate: activate)
    }

    /// Applies the selected tab to chat/spaces/module without re-entrancy.
    func applySelection(
        module: inout AppModule,
        chat: ChatViewModel,
        spaces: SpacesViewModel
    ) {
        guard !suppressSelectionSync, let tab = selectedTab else { return }
        suppressSelectionSync = true
        defer { suppressSelectionSync = false }

        switch tab.kind {
        case .app(let appModule):
            module = appModule == .settings ? .chat : appModule
        case .chatChannel(let id), .chatDirectMessage(let id):
            module = .chat
            chat.selectChannelById(id, recordHistory: true)
        case .space(let id):
            module = .spaces
            Task { await spaces.selectSpace(id, recordHistory: true) }
        }
    }

    func syncTabMetadata(chat: ChatViewModel, spaces: SpacesViewModel) {
        for index in tabs.indices {
            switch tabs[index].kind {
            case .chatChannel(let id), .chatDirectMessage(let id):
                let all = chat.channels + chat.directMessages
                if let channel = all.first(where: { $0.id == id }) {
                    tabs[index] = .chat(channel)
                }
            case .space(let id):
                if let space = spaces.spaces.first(where: { $0.id == id }) {
                    tabs[index] = .space(space)
                }
            case .app:
                break
            }
        }
    }

    func reflectChannelSelection(_ channel: ChatChannel?) {
        guard !suppressSelectionSync else { return }
        guard let channel else { return }
        suppressSelectionSync = true
        openFromChannel(channel, activate: true)
        suppressSelectionSync = false
    }

    func reflectSpaceSelection(_ space: SpaceRecord?) {
        guard !suppressSelectionSync else { return }
        guard let space else { return }
        suppressSelectionSync = true
        openFromSpace(space, activate: true)
        suppressSelectionSync = false
    }

    // MARK: - Detach

    func detachTab(
        _ tab: WorkspaceTab,
        chat: ChatViewModel,
        spaces: SpacesViewModel,
        auth: AuthViewModel,
        subscription: SubscriptionService
    ) {
        switch tab.kind {
        case .chatChannel, .chatDirectMessage:
            let id: UUID = {
                switch tab.kind {
                case .chatChannel(let cid), .chatDirectMessage(let cid): return cid
                default: return UUID()
                }
            }()
            let all = chat.channels + chat.directMessages
            if let channel = all.first(where: { $0.id == id }) {
                ChatWindowManager.shared.openChannel(channel, chat: chat, auth: auth)
            }
        case .space(let id):
            if let space = spaces.spaces.first(where: { $0.id == id }) {
                SpacesWindowManager.shared.openSpace(space, spaces: spaces, auth: auth)
            }
        case .app(let module):
            guard module != .settings else { return }
            WorkspaceModuleWindowManager.shared.open(
                module: module,
                chat: chat,
                spaces: spaces,
                auth: auth,
                subscription: subscription
            )
        }
    }
}
