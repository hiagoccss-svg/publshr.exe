import SwiftUI

// MARK: - Native titlebar control (traffic-light row)

struct TitlebarChromeIconButton: View {
    let systemName: String
    var help: String = ""
    var isEnabled: Bool = true
    var isActive: Bool = false
    var isLoading: Bool = false
    var badgeCount: Int = 0
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        TitlebarToolbarSlot {
            Button(action: action) {
                ZStack {
                    Group {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.55)
                        } else {
                            Image(systemName: systemName)
                                .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .regular))
                                .symbolRenderingMode(.monochrome)
                        }
                    }
                    .foregroundStyle(foregroundColor)
                    .frame(
                        width: AppWindowChromeMetrics.controlSize,
                        height: AppWindowChromeMetrics.controlSize
                    )
                    .background(backgroundShape)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                            .strokeBorder(strokeColor, lineWidth: isActive ? 1 : 0)
                    )

                    if badgeCount > 0 {
                        Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(CursorTheme.accent))
                            .offset(x: 8, y: -6)
                    }
                }
                .frame(
                    width: AppWindowChromeMetrics.controlSize,
                    height: AppWindowChromeMetrics.controlSize
                )
                .clipped()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled || isLoading)
            .help(help)
            .onHover { isHovered = $0 }
        }
    }

    private var foregroundColor: Color {
        if !isEnabled { return LibraryGlassDesign.inkMuted.opacity(0.35) }
        if isActive { return LibraryGlassDesign.ink }
        return isHovered ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
            .fill(backgroundFill)
    }

    private var backgroundFill: Color {
        if isActive { return MacSystemChrome.toolbarPressedFill }
        if isHovered && isEnabled { return MacSystemChrome.toolbarHoverFill }
        return Color.clear
    }

    private var strokeColor: Color {
        Color.clear
    }
}

/// Profile avatar menu locked to the shared toolbar slot (no chevron, no extra menu padding).
struct TitlebarToolbarProfileMenu: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel

    var isUploadingAvatar: Bool = false
    var showChatPermissions: Bool = true
    var onUploadPhoto: (() -> Void)?
    var onChatPermissions: (() -> Void)?

    var body: some View {
        TitlebarToolbarSlot {
            Menu {
                if let profile = auth.profile {
                    HStack(spacing: 10) {
                        ChatProfileAvatar(
                            profile: profile,
                            displayName: profile.displayName ?? profile.email,
                            size: 36,
                            presence: chat.myStatus
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.displayName ?? profile.email)
                                .font(.headline)
                            HStack(spacing: 4) {
                                ChatPresenceDot(status: chat.myStatus, size: 8)
                                Text(chat.myStatus.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                Divider()
                if let onUploadPhoto {
                    Button {
                        onUploadPhoto()
                    } label: {
                        Label(isUploadingAvatar ? "Uploading…" : "Upload photo", systemImage: "photo")
                    }
                    .disabled(isUploadingAvatar)
                    Divider()
                }
                Text("Set status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(ChatPresenceStatus.allCases.filter { $0 != .invisible }, id: \.self) { status in
                    Button {
                        Task { await chat.setStatus(status) }
                    } label: {
                        Label(
                            status.label,
                            systemImage: status == chat.myStatus ? "checkmark.circle.fill" : "circle.fill"
                        )
                    }
                }
                Divider()
                Button("Account & profile") {
                    NotificationCenter.default.post(name: .publshrOpenSettings, object: SettingsSection.account.rawValue)
                }
                Button("Workspace settings") {
                    NotificationCenter.default.post(name: .publshrOpenSettings, object: SettingsSection.workspace.rawValue)
                }
                if showChatPermissions, let onChatPermissions {
                    Button("Chat permissions") {
                        onChatPermissions()
                    }
                }
                Divider()
                Button("Sign out", role: .destructive) {
                    Task { await auth.signOut() }
                }
            } label: {
                profileLabel
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Profile & photo")
        }
    }

    @ViewBuilder
    private var profileLabel: some View {
        if let profile = auth.profile {
            ChatProfileAvatar(
                profile: profile,
                displayName: profile.displayName ?? profile.email,
                size: AppWindowChromeMetrics.controlSize - 4,
                presence: nil
            )
        } else {
            Image(systemName: "person.circle.fill")
                .font(.system(size: AppWindowChromeMetrics.controlIconSize))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
        }
    }
}

struct TitlebarChromeDivider: View {
    var body: some View {
        Rectangle()
            .fill(LibraryGlassDesign.hairline)
            .frame(width: 1, height: 16)
            .padding(.horizontal, 2)
    }
}

/// Workspace / profile menus — same chrome metrics as icon buttons.
struct TitlebarChromeMenuLabel: View {
    let title: String
    var systemImage: String? = nil
    var isActive: Bool = false

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .medium))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(isActive || isHovered ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
        .padding(.horizontal, 8)
        .frame(height: AppWindowChromeMetrics.controlSize)
        .background(
            RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                .fill(
                    isActive
                        ? LibraryGlassDesign.documentTabSelectedFill
                        : (isHovered ? Color.white.opacity(0.55) : Color.white.opacity(0.32))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                .strokeBorder(CursorMacShellDesign.borderSubtle, lineWidth: 0.5)
        )
        .onHover { isHovered = $0 }
    }
}
