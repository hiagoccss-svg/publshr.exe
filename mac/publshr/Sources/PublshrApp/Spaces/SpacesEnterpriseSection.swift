import Foundation

/// Operations sidebar sections — keep aligned with `shared/enterprise/sidebar-sections.ts`.
enum SpacesEnterpriseSection: String, CaseIterable, Identifiable {
    case dashboard
    case spaces
    case planner
    case chat
    case documents
    case approvals
    case reports
    case clients
    case campaigns
    case team
    case media
    case files
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .spaces: return "Spaces"
        case .planner: return "Planner"
        case .chat: return "Chat"
        case .documents: return "Documents"
        case .approvals: return "Approvals"
        case .reports: return "Reports"
        case .clients: return "Clients"
        case .campaigns: return "Campaigns"
        case .team: return "Team"
        case .media: return "Media Monitoring"
        case .files: return "Files"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .spaces: return "folder"
        case .planner: return "calendar"
        case .chat: return "bubble.left.and.bubble.right"
        case .documents: return "doc.text"
        case .approvals: return "checkmark.circle"
        case .reports: return "chart.bar"
        case .clients: return "briefcase"
        case .campaigns: return "megaphone"
        case .team: return "person.2"
        case .media: return "dot.radiowaves.left.and.right"
        case .files: return "archivebox"
        case .settings: return "gearshape"
        }
    }

    /// Primary nav strip (settings pinned in footer).
    static let mainNav: [SpacesEnterpriseSection] = [
        .dashboard, .spaces, .planner, .chat, .documents, .approvals, .reports,
        .clients, .campaigns, .team, .media, .files
    ]
}
