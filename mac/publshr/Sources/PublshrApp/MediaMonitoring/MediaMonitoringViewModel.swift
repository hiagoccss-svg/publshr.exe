import Foundation
import Supabase

@MainActor
final class MediaMonitoringViewModel: ObservableObject {
    @Published private(set) var monitors: [MediaMonitorRecord] = []
    @Published private(set) var results: [MediaMonitorResultRecord] = []
    @Published var selectedMonitorId: UUID?
    @Published var selectedResultId: UUID?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var newMonitorName = ""
    @Published var newMonitorKeywords = ""

    private var service: MacMediaMonitoringService?
    private var workspaceId: UUID?
    private var userId: UUID?

    func attach(auth: AuthViewModel) {
        service = MacMediaMonitoringService(client: auth.client)
        workspaceId = auth.selectedWorkspace?.id
        userId = auth.session?.user.id ?? auth.profile?.id
        Task { await reload() }
    }

    func reload() async {
        guard let service, let workspaceId else {
            monitors = []
            results = []
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            monitors = try await service.fetchMonitors(workspaceId: workspaceId)
            if selectedMonitorId == nil {
                selectedMonitorId = monitors.first?.id
            }
            await loadResults()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadResults() async {
        guard let service, let monitorId = selectedMonitorId else {
            results = []
            return
        }
        do {
            results = try await service.fetchResults(monitorId: monitorId)
            if selectedResultId == nil {
                selectedResultId = results.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectMonitor(_ id: UUID?) async {
        selectedMonitorId = id
        selectedResultId = nil
        await loadResults()
    }

    func createMonitor() async {
        guard let service, let workspaceId, let userId else { return }
        let name = newMonitorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let keywords = newMonitorKeywords.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !keywords.isEmpty else { return }
        do {
            let monitor = try await service.createMonitor(
                workspaceId: workspaceId,
                userId: userId,
                name: name,
                keywords: keywords
            )
            monitors.insert(monitor, at: 0)
            newMonitorName = ""
            newMonitorKeywords = ""
            await selectMonitor(monitor.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var selectedResult: MediaMonitorResultRecord? {
        guard let selectedResultId else { return nil }
        return results.first { $0.id == selectedResultId }
    }
}
