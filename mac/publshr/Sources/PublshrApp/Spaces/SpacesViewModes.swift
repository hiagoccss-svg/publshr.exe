import Foundation

/// Must match `shared/spaces/view-modes.ts` (Electron renderer ↔ macOS IDE).
enum SpacesViewModes {
    static let tabOrder: [SpacesViewModel.TaskViewMode] = [
        .overview, .list, .board, .whiteboard, .calendar, .timeline, .workload, .priority
    ]
}
