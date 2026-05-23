import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// macOS-native image pick — more reliable than `fileImporter` inside sheets.
enum ProfileImagePicker {
    @MainActor
    static func pickImage() async -> URL? {
        await withCheckedContinuation { continuation in
            let panel = NSOpenPanel()
            panel.title = "Choose profile photo"
            panel.allowedContentTypes = [.jpeg, .png]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.begin { response in
                continuation.resume(returning: response == .OK ? panel.url : nil)
            }
        }
    }

    @MainActor
    static func loadImageData(from url: URL) throws -> (Data, String) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let mime = url.pathExtension.lowercased() == "png" ? "image/png" : "image/jpeg"
        return (data, mime)
    }
}

struct ProfilePhotoPickerButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(isLoading ? "Uploading…" : title, action: action)
            .disabled(isLoading)
    }
}
