#!/usr/bin/env swift
// Generates AppIcon.icns from mac/publshr/app/icon.png (or programmatic fallback).
import AppKit
import Foundation

let outIcns = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.icns")
let sourcePNG: URL? = CommandLine.arguments.count > 2
    ? URL(fileURLWithPath: CommandLine.arguments[2])
    : nil

func drawWhiteIconBackground(in rect: NSRect) {
    NSColor.white.setFill()
    NSBezierPath(rect: rect).fill()
}

func loadSourceImage() -> NSImage {
    if let src = sourcePNG, FileManager.default.fileExists(atPath: src.path),
       let loaded = NSImage(contentsOf: src) {
        let side = max(loaded.size.width, loaded.size.height)
        let canvas = NSImage(size: NSSize(width: side, height: side))
        canvas.lockFocus()
        let full = NSRect(x: 0, y: 0, width: side, height: side)
        drawWhiteIconBackground(in: full)
        let inset = side * 0.04
        let draw = NSRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
        loaded.draw(in: draw, from: .zero, operation: .sourceOver, fraction: 1)
        canvas.unlockFocus()
        return canvas
    }

    let size: CGFloat = 1024
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    drawWhiteIconBackground(in: NSRect(x: 0, y: 0, width: size, height: size))
    image.unlockFocus()
    return image
}

let image = loadSourceImage()
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
    if let png = rep.representation(using: .png, properties: [:]) {
        try png.write(to: iconset.appendingPathComponent(name))
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
