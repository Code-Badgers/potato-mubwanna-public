import AppKit
import Foundation

let frontend = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let sourceURL = frontend.appendingPathComponent("assets/app_logo_2.png")
guard let source = NSImage(contentsOf: sourceURL) else {
    fatalError("Missing app icon source: \(sourceURL.path)")
}

func writeIcon(at relativePath: String, size: Int) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not create \(size)x\(size) icon")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    // iOS applies its own rounded mask; a green backing avoids white corners from source alpha.
    NSColor(srgbRed: 61 / 255, green: 148 / 255, blue: 69 / 255, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    source.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(relativePath)")
    }
    try data.write(to: frontend.appendingPathComponent(relativePath))
}

let iosSizes: [(String, Int)] = [
    ("20x20@1x", 20), ("20x20@2x", 40), ("20x20@3x", 60),
    ("29x29@1x", 29), ("29x29@2x", 58), ("29x29@3x", 87),
    ("40x40@1x", 40), ("40x40@2x", 80), ("40x40@3x", 120),
    ("60x60@2x", 120), ("60x60@3x", 180),
    ("76x76@1x", 76), ("76x76@2x", 152),
    ("83.5x83.5@2x", 167), ("1024x1024@1x", 1024),
]
for (name, size) in iosSizes {
    try writeIcon(
        at: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-\(name).png",
        size: size
    )
}
