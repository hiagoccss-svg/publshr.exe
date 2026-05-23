import AppKit
import Foundation
import UniformTypeIdentifiers

extension ChatViewModel {
    func syncChannelLastRead(for channel: ChatChannel) async {
        guard let service, let workspace, let userId = currentUserId else { return }
        let member: ChatChannelMember?
        if channel.id == selectedChannel?.id, let mine = myChannelMemberRecord() {
            member = mine
        } else if let fetched = try? await service.fetchChannelMembers(
            channelId: channel.id,
            workspaceId: workspace.id
        ) {
            member = fetched.first { $0.userId == userId }
        } else {
            member = nil
        }
        guard let member else { return }
        try? await service.updateMemberLastRead(
            memberId: member.id,
            workspaceId: workspace.id,
            lastReadAt: Date()
        )
    }

    func pasteFromClipboard() async {
        guard permissions.canUploadFiles else {
            errorMessage = "File uploads are disabled in this workspace."
            return
        }
        guard let payload = ChatPasteboardSupport.extractUploadable() else {
            errorMessage = "Clipboard has no image or file to paste."
            return
        }
        await uploadData(
            payload.data,
            fileName: payload.fileName,
            mimeType: payload.mimeType
        )
    }

    func uploadData(_ data: Data, fileName: String, mimeType: String) async {
        guard permissions.canUploadFiles,
              let service, let workspace, let channel = selectedChannel,
              let userId = currentUserId else { return }
        uploadProgress = 0.1
        do {
            let result = try await service.uploadChatFile(
                workspaceId: workspace.id,
                userId: userId,
                fileName: fileName,
                mimeType: mimeType,
                data: data
            )
            uploadProgress = 0.7
            let attachmentType: String = {
                if mimeType.hasPrefix("image/") { return "image" }
                if mimeType.hasPrefix("video/") { return "video" }
                return "file"
            }()
            let attachment = ChatAttachment(
                type: attachmentType,
                url: result.publicURL.absoluteString,
                name: fileName,
                size: data.count
            )
            let body = attachmentType == "image" ? "Shared an image" : "Shared \(fileName)"
            let msg = try await service.sendMessageExtended(
                workspaceId: workspace.id,
                channelId: channel.id,
                userId: userId,
                body: body,
                attachments: [attachment]
            )
            messages.append(msg)
            uploadProgress = 1
            try? await Task.sleep(nanoseconds: 300_000_000)
            uploadProgress = nil
            errorMessage = nil
            await loadChannelExtras()
        } catch {
            uploadProgress = nil
            errorMessage = friendlyChatUploadError(error)
        }
    }

    func friendlyChatUploadError(_ error: Error) -> String {
        let text = String(describing: error).lowercased()
        if text.contains("bucket") || text.contains("storage") || text.contains("row-level security") {
            return "Upload blocked. Ask your admin to enable the workspace-files bucket and storage policies in Supabase."
        }
        if text.contains("payload too large") || text.contains("413") {
            return "File is too large for the server limit."
        }
        return error.localizedDescription
    }

    func playIncomingMessageSoundIfEnabled() {
        guard ChatUserPreferences.playMessageSound else { return }
        if let sound = NSSound(named: "Tink") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    func bootstrapDesktopChatPermissions() async {
        _ = await ChatNotificationService.shared.requestAuthorizationIfNeeded()
    }
}
