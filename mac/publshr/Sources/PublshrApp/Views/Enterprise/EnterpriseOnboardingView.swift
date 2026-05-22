import SwiftUI

/// Post-install / first sign-in enterprise setup — privacy, device, plan acknowledgment.
struct EnterpriseOnboardingView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @Binding var isPresented: Bool

    @State private var acceptedPrivacy = false
    @State private var step = 0

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            VStack(spacing: 24) {
                PublshrBrandLogoView(size: 56, cornerRadius: 14)
                Text("Enterprise setup")
                    .font(.title.weight(.semibold))
                Text("Configure privacy, register this Mac, and confirm your workspace plan before using Chat and Spaces.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)

                Group {
                    switch step {
                    case 0: privacyStep
                    case 1: deviceStep
                    default: planStep
                    }
                }
                .frame(maxWidth: 440)

                HStack {
                    if step > 0 {
                        Button("Back") { step -= 1 }
                    }
                    Spacer()
                    Button(step < 2 ? "Continue" : "Get started") {
                        if step < 2 {
                            step += 1
                        } else {
                            finish()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(step == 0 && !acceptedPrivacy)
                }
                .padding(.top, 8)
            }
            .padding(40)
        }
        .frame(minWidth: 520, minHeight: 480)
        .task {
            await subscription.refresh(client: auth.client, workspace: auth.selectedWorkspace)
        }
    }

    private var privacyStep: some View {
        Form {
            Section {
                Toggle("I agree to the Privacy Policy and Terms of Service", isOn: $acceptedPrivacy)
                Link("Privacy Policy", destination: PrivacyConsentStore.privacyPolicyURL)
                Link("Terms of Service", destination: PrivacyConsentStore.termsURL)
            }
        }
        .formStyle(.grouped)
    }

    private var deviceStep: some View {
        Form {
            Section("This Mac") {
                let info = DeviceIdentityService.current
                LabeledContent("Computer", value: info.deviceName)
                LabeledContent("Model", value: info.modelIdentifier)
                Text("We register this device for security and session management. You can review devices in Settings → Devices.")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
    }

    private var planStep: some View {
        Form {
            Section("Workspace plan") {
                LabeledContent("Plan", value: subscription.features.planName)
                LabeledContent("Seats", value: "\(subscription.features.seatLimit)")
                LabeledContent("Chat", value: subscription.features.chatEnabled ? "Included" : "—")
                LabeledContent("Spaces", value: subscription.features.spacesEnabled ? "Included" : "—")
            }
        }
        .formStyle(.grouped)
    }

    private func finish() {
        PrivacyConsentStore.accept()
        Task {
            if let uid = auth.profile?.id {
                await PrivacyConsentStore.logAcceptance(client: auth.client, userId: uid, workspaceId: auth.selectedWorkspace?.id)
                await DeviceIdentityService.register(client: auth.client, userId: uid, workspaceId: auth.selectedWorkspace?.id)
            }
            EnterpriseInstallState.markCompleted()
            isPresented = false
        }
    }
}
