import Foundation
import Supabase

@MainActor
final class MediaMonitoringViewModel: ObservableObject {
    @Published private(set) var profiles: [MonitorProfileRecord] = []
    @Published private(set) var results: [MonitorResultRecord] = []
    @Published private(set) var savedResultIds: Set<UUID> = []
    @Published var selectedProfileId: UUID?
    @Published var selectedResultId: UUID?
    @Published var filter: MediaMonitoringFilter = .all
    @Published var searchQuery = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var service: MediaMonitoringService?
    private var workspaceId: UUID?

    func attach(auth: AuthViewModel) {
        let ws = auth.selectedMembership?.workspace.id
        let changed = workspaceId != ws
        workspaceId = ws
        service = MediaMonitoringService(client: auth.client)
        if changed || profiles.isEmpty {
            Task { await reload() }
        }
    }

    func detach() {
        service = nil
        workspaceId = nil
        profiles = []
        results = []
        savedResultIds = []
        selectedProfileId = nil
        selectedResultId = nil
    }

    func reload() async {
        guard let service, let workspaceId else {
            profiles = []
            results = []
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            profiles = try await service.fetchProfiles(workspaceId: workspaceId)
            savedResultIds = try await service.fetchSavedResultIds(workspaceId: workspaceId)
            if selectedProfileId == nil {
                selectedProfileId = profiles.first(where: \.isActive)?.id ?? profiles.first?.id
            }
            if let profileId = selectedProfileId {
                await loadResults(profileId: profileId)
            } else {
                results = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectProfile(_ id: UUID) async {
        selectedProfileId = id
        selectedResultId = nil
        await loadResults(profileId: id)
    }

    func selectResult(_ id: UUID) {
        selectedResultId = id
    }

    func loadResults(profileId: UUID) async {
        guard let service else { return }
        do {
            results = try await service.fetchResults(profileId: profileId)
            if selectedResultId == nil {
                selectedResultId = filteredResults.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
    }

    func saveSelectedResult() async {
        guard let service, let workspaceId, let resultId = selectedResultId else { return }
        do {
            try await service.saveCoverage(workspaceId: workspaceId, resultId: resultId)
            savedResultIds.insert(resultId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var filteredResults: [MonitorResultRecord] {
        var list = results
        switch filter {
        case .all:
            break
        case .saved:
            list = list.filter { savedResultIds.contains($0.id) }
        case .alerts:
            list = list.filter { $0.sentiment == "negative" || $0.relevanceScore >= 0.85 }
        }
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return list }
        return list.filter {
            $0.title.lowercased().contains(q)
                || ($0.author?.lowercased().contains(q) ?? false)
                || ($0.url?.lowercased().contains(q) ?? false)
        }
    }

    var selectedResult: MonitorResultRecord? {
        guard let selectedResultId else { return nil }
        return results.first { $0.id == selectedResultId }
    }

    var selectedProfile: MonitorProfileRecord? {
        guard let selectedProfileId else { return nil }
        return profiles.first { $0.id == selectedProfileId }
    }
}
