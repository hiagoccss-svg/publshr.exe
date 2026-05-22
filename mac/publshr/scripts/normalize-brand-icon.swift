#!/usr/bin/env swift
// Composite repository-root icon.png onto a full white square (default 1024×1024).
import AppKit
import Foundation

let sourcePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
let destPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ""
let size = CommandLine.arguments.count > 3 ? (CGFloat(Int(CommandLine.arguments[3]) ?? 1024)) : 1024

guard !sourcePath.isEmpty, !destPath.isEmpty,
      FileManager.default.fileExists(atPath: sourcePath),
      let loaded = NSImage(contentsOf: URL(fileURLWithPath: sourcePath)) else {
    fputs("Usage: normalize-brand-icon.swift <source.png> <dest.png> [size]\n", stderr)
    exit(1)
}

let px = Int(size)
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
let full = NSRect(x: 0, y: 0, width: size, height: size)
NSColor.white.setFill()
NSBezierPath(rect: full).fill()
let inset = size * 0.04
let draw = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
loaded.draw(in: draw, from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

let dest = URL(fileURLWithPath: destPath)
try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: dest)
print("normalize-brand-icon: \(sourcePath) → \(destPath) (\(Int(size))×\(Int(size)), white background)")
