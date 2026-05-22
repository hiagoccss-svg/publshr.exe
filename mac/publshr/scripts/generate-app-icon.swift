#!/usr/bin/env swift
// Generates AppIcon.icns for Publshr.app (run on macOS during packaging).
import AppKit
import Foundation

let outIcns = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : URL(fileURLWithPath: "AppIcon.icns")

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

NSColor(calibratedRed: 0.09, green: 0.09, blue: 0.10, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

let accent = NSColor(calibratedRed: 0.0, green: 0.48, blue: 0.83, alpha: 1)
accent.setFill()

// Cursor-style chevron mark
let chevron = NSBezierPath()
chevron.move(to: NSPoint(x: size * 0.28, y: size * 0.72))
chevron.line(to: NSPoint(x: size * 0.46, y: size * 0.50))
chevron.line(to: NSPoint(x: size * 0.28, y: size * 0.28))
chevron.line(to: NSPoint(x: size * 0.38, y: size * 0.28))
chevron.line(to: NSPoint(x: size * 0.56, y: size * 0.50))
chevron.line(to: NSPoint(x: size * 0.38, y: size * 0.72))
chevron.close()
chevron.fill()

let chevron2 = NSBezierPath()
chevron2.move(to: NSPoint(x: size * 0.50, y: size * 0.72))
chevron2.line(to: NSPoint(x: size * 0.68, y: size * 0.50))
chevron2.line(to: NSPoint(x: size * 0.50, y: size * 0.28))
chevron2.line(to: NSPoint(x: size * 0.60, y: size * 0.28))
chevron2.line(to: NSPoint(x: size * 0.78, y: size * 0.50))
chevron2.line(to: NSPoint(x: size * 0.60, y: size * 0.72))
chevron2.close()
chevron2.fill()

image.unlockFocus()

let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("PublshrIcon-\(UUID().uuidString)")
try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: tmp) }

let iconset = tmp.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let slots: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (px, name) in slots {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px,
        pixelsHigh: px,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: CGFloat(px), height: CGFloat(px)))
    NSGraphicsContext.restoreGraphicsState()
    let url = iconset.appendingPathComponent(name)
    if let png = rep.png {
        try png.write(to: url)
    }
}

let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", iconset.path, "-o", outIcns.path]
try proc.run()
proc.waitUntilExit()
guard proc.terminationStatus == 0 else {
    fputs("iconutil failed\n", stderr)
    exit(1)
}
print("Wrote \(outIcns.path)")

private extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}
