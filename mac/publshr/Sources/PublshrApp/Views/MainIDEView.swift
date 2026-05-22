import SwiftUI

struct MainIDEView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    @AppStorage("publshr.selectedModule") private var storedModule = AppModule.chat.rawValue
    @State private var module: AppModule = .chat
    @State private var showNewChannel = false
    @State private var showNewDM = false

    var body: some View {
        VStack(spacing: 0) {
            AppUpdateBannerView(updates: updates)

            HStack(alignment: .top, spacing: 0) {
                ActivityBarView(module: $module)
                    .frame(width: CursorTheme.activityBarWidth)
                    .frame(maxHeight: .infinity)

                AppSecondarySidebar(
                    module: module,
                    chat: chat,
                    spaces: spaces,
                    showNewChannel: $showNewChannel,
                    showNewDM: $showNewDM
                )

                VStack(spacing: 0) {
                    TitleBarView(module: module)
                        .frame(height: CursorTheme.titleBarHeight)

                    moduleMainContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    StatusBarView(module: module)
                        .frame(height: CursorTheme.statusBarHeight)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(CursorTheme.editorBackground)
        .onAppear {
            if let restored = AppModule(rawValue: storedModule) {
                module = restored
            }
            chat.attach(auth: auth)
            spaces.attach(auth: auth)
        }
        .onChange(of: module) { _, newModule in
            storedModule = newModule.rawValue
            if newModule == .chat {
                chat.attach(auth: auth)
            }
            if newModule == .spaces {
                spaces.attach(auth: auth)
            }
        }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            if module == .spaces {
                spaces.attach(auth: auth)
            }
            if module == .chat {
                chat.attach(auth: auth)
            }
        }
        .sheet(isPresented: $showNewChannel) { newChannelSheet }
        .sheet(isPresented: $showNewDM) { newDMSheet }
    }

    @ViewBuilder
    private var moduleMainContent: some View {
        switch module {
        case .chat:
            EnterpriseChatView(chat: chat)
                .onAppear { chat.attach(auth: auth) }
        case .spaces:
            SpacesRootView(spaces: spaces)
        case .settings:
            SettingsView()
        }
    }

    private var newChannelSheet: some View {
        NewChannelSheet(chat: chat, isPresented: $showNewChannel)
    }

    private var newDMSheet: some View {
        NewDMSheet(chat: chat, isPresented: $showNewDM)
    }
}

// MARK: - Sheets (shared with sidebar actions)

private struct NewChannelSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var isPresented: Bool
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Channel").font(.headline)
            TextField("Channel name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Create") {
                    Task {
                        await chat.createChannel(name: name)
                        isPresented = false
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

private struct NewDMSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Message").font(.headline)
            List(Array(chat.profiles.values).sorted { ($0.displayName ?? $0.email) < ($1.displayName ?? $1.email) }) { profile in
                if profile.id != chat.currentUserId {
                    Button {
                        Task {
                            await chat.openDM(with: profile)
                            isPresented = false
                        }
                    } label: {
                        HStack {
                            ChatPresenceDot(status: chat.presence(for: profile.id))
                            Text(profile.displayName ?? profile.email)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(minHeight: 200)
            Button("Close") { isPresented = false }
        }
        .padding(20)
        .frame(width: 320, height: 360)
    }
}
