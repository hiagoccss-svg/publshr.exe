import Foundation

struct MonitorProfileRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    var name: String
    var keywords: String
    var isActive: Bool
    var linkedClient: String?
    var linkedCampaign: String?

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case name, keywords
        case isActive = "is_active"
        case linkedClient = "linked_client"
        case linkedCampaign = "linked_campaign"
    }
}

struct MonitorResultRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let monitorProfileId: UUID
    var title: String
    var url: String?
    var author: String?
    var publishedAt: String?
    var sentiment: String
    var reach: Int64
    var mediaValue: Double
    var relevanceScore: Double
    var coverageType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case monitorProfileId = "monitor_profile_id"
        case title, url, author
        case publishedAt = "published_at"
        case sentiment, reach
        case mediaValue = "media_value"
        case relevanceScore = "relevance_score"
        case coverageType = "coverage_type"
    }
}

enum MediaMonitoringFilter: String, CaseIterable, Identifiable {
    case all
    case saved
    case alerts

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All coverage"
        case .saved: return "Saved clips"
        case .alerts: return "Alerts"
        }
    }

    var icon: String {
        switch self {
        case .all: return "dot.radiowaves.left.and.right"
        case .saved: return "bookmark"
        case .alerts: return "bell.badge"
        }
    }
}
