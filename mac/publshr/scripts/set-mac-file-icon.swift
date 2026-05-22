#!/usr/bin/env swift
// Sets Finder icon for a file (.command, folder) from PNG — macOS only.
import AppKit
import Foundation

guard CommandLine.arguments.count >= 3 else {
    fputs("Usage: set-mac-file-icon.swift <target-path> <icon.png>\n", stderr)
    exit(1)
}

let target = CommandLine.arguments[1]
let png = URL(fileURLWithPath: CommandLine.arguments[2])
guard FileManager.default.fileExists(atPath: target),
      let image = NSImage(contentsOf: png) else {
    fputs("Missing target or icon\n", stderr)
    exit(1)
}

NSWorkspace.shared.setIcon(image, forFile: target, options: [])
print("Set icon on \(target)")
