import AppKit
import UniformTypeIdentifiers

enum ChatPasteboardSupport {
    /// Returns file URL or in-memory image suitable for chat upload.
    static func extractUploadable() -> (data: Data, fileName: String, mimeType: String)? {
        let pb = NSPasteboard.general

        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true,
        ]) as? [URL], let url = urls.first {
            guard let data = try? Data(contentsOf: url) else { return nil }
            let name = url.lastPathComponent
            let mime = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            return (data, name, mime)
        }

        if let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
           let image = images.first,
           let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            return (png, "pasted-\(Int(Date().timeIntervalSince1970)).png", "image/png")
        }

        if let string = pb.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           string.hasPrefix("http://") || string.hasPrefix("https://"),
           let url = URL(string: string) {
            return nil
        }

        return nil
    }
}
