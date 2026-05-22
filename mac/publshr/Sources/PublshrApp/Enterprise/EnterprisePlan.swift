import Foundation

/// Subscription tiers — gates Chat, Spaces, calls, and seats.
enum EnterprisePlanId: String, CaseIterable, Identifiable {
    case trial
    case team
    case enterprise

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .trial: return "Trial"
        case .team: return "Team"
        case .enterprise: return "Enterprise"
        }
    }
}

struct SubscriptionPlanRecord: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let seatLimit: Int
    let includesChat: Bool
    let includesSpaces: Bool
    let includesCalls: Bool
    let includesFilesGb: Int
    let priceLabel: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case seatLimit = "seat_limit"
        case includesChat = "includes_chat"
        case includesSpaces = "includes_spaces"
        case includesCalls = "includes_calls"
        case includesFilesGb = "includes_files_gb"
        case priceLabel = "price_label"
    }

    static let fallbackTrial = SubscriptionPlanRecord(
        id: "trial",
        name: "Trial",
        seatLimit: 3,
        includesChat: true,
        includesSpaces: true,
        includesCalls: true,
        includesFilesGb: 5,
        priceLabel: "Free trial"
    )
}

struct EnterpriseFeatureFlags: Equatable {
    var chatEnabled = true
    var spacesEnabled = true
    var callsEnabled = true
    var fileUploadEnabled = true
    var seatLimit = 3
    var planName = "Trial"
    var priceLabel = "Free trial"

    static func from(plan: SubscriptionPlanRecord) -> EnterpriseFeatureFlags {
        EnterpriseFeatureFlags(
            chatEnabled: plan.includesChat,
            spacesEnabled: plan.includesSpaces,
            callsEnabled: plan.includesCalls,
            fileUploadEnabled: true,
            seatLimit: plan.seatLimit,
            planName: plan.name,
            priceLabel: plan.priceLabel
        )
    }
}
