import Foundation
import Supabase

@MainActor
final class SubscriptionService: ObservableObject {
    @Published private(set) var plan: SubscriptionPlanRecord = .fallbackTrial
    @Published private(set) var features = EnterpriseFeatureFlags.from(plan: .fallbackTrial)
    @Published private(set) var memberCount = 0
    @Published var billingMessage: String?

    func refresh(client: SupabaseClient, workspace: Workspace?) async {
        guard let workspace else {
            plan = .fallbackTrial
            features = .from(plan: plan)
            return
        }
        let planId = workspace.planId.isEmpty ? "trial" : workspace.planId
        do {
            let rows: [SubscriptionPlanRecord] = try await client
                .from("subscription_plans")
                .select()
                .eq("id", value: planId)
                .limit(1)
                .execute()
                .value
            plan = rows.first ?? .fallbackTrial
            features = .from(plan: plan)
        } catch {
            plan = .fallbackTrial
            features = .from(plan: plan)
        }

        do {
            struct MemberRow: Decodable { let userId: UUID; enum CodingKeys: String { case userId = "user_id" } }
            let rows: [MemberRow] = try await client
                .from("workspace_members")
                .select("user_id")
                .eq("workspace_id", value: workspace.id.uuidString)
                .execute()
                .value
            memberCount = rows.count
        } catch {
            memberCount = 0
        }

        if memberCount > features.seatLimit {
            billingMessage = "This workspace has \(memberCount) members but the \(features.planName) plan allows \(features.seatLimit). Upgrade to add more seats."
        } else {
            billingMessage = nil
        }
    }

    func canUseChat(workspace: Workspace?) -> Bool {
        features.chatEnabled
    }

    func canUseSpaces(workspace: Workspace?) -> Bool {
        features.spacesEnabled
    }

    func canUseCalls(workspace: Workspace?) -> Bool {
        features.callsEnabled
    }
}
