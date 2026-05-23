import SwiftUI

/// Signed-in user at the bottom of the primary bar menu — opens profile & team sheet.
struct LibraryBarMenuProfileFooter: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var profilePresentation: WorkspaceProfilePresentation?

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LibraryGlassDesign.contentDivider.opacity(0.55))
                .frame(height: 1)
                .padding(.horizontal, 10)

            Button {
                profilePresentation = .currentUser
            } label: {
                HStack(spacing: 10) {
                    if let profile = auth.profile {
                        ChatProfileAvatar(
                            profile: profile,
                            displayName: profile.displayName ?? profile.email,
                            size: 34,
                            presence: chat.myStatus
                        )
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(LibraryGlassDesign.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(chat.myStatus.label)
                            .font(.system(size: 11))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Your profile & workspace team")
        }
        .frame(minHeight: ChatClickUpDesign.footerHeight, alignment: .center)
    }

    private var displayTitle: String {
        auth.profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
            ?? auth.profile?.email
            ?? "Set up profile"
    }
}

private extension String {
    var nonEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
