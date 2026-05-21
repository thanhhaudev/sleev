import AppKit
import Foundation

// App icon generator for sleev.
//
// Draws the sleeve-handle glyph (•••◀) in white on a graphite squircle and
// writes every size the macOS AppIcon set needs, plus its Contents.json.
//
// Run from the repo root:  swift Tools/generate-app-icon.swift   (or `make app-icon`)
//
// Glyph proportions mirror Sleev/StatusBar/SleeveGlyph.swift:
// dot 3u, dot gap 2.5u, group gap 2.5u, triangle 6u wide x 8u tall;
// total glyph width = 3*3 + 2*2.5 + 2.5 + 6 = 22.5u.

let pixelSizes = [16, 32, 64, 128, 256, 512, 1024]

func glyphFraction(forPixelSize size: Int) -> CGFloat {
    switch size {
    case ...32: return 0.72
    case 33 ... 128: return 0.62
    default: return 0.56
    }
}

func srgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

let topColor = srgb(58 / 255, 58 / 255, 60 / 255)     // #3A3A3C
let bottomColor = srgb(22 / 255, 22 / 255, 24 / 255)  // #161618
let glyphColor = srgb(1, 1, 1)                        // #FFFFFF

func renderIcon(pixelSize: Int) -> CGImage {
    let canvas = CGFloat(pixelSize)
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    // Squircle plate, centred, 80% of the canvas.
    let plateSide = (canvas * 0.80).rounded()
    let plateOrigin = ((canvas - plateSide) / 2).rounded()
    let plateRect = CGRect(x: plateOrigin, y: plateOrigin, width: plateSide, height: plateSide)
    let cornerRadius = plateSide * 0.2237
    let platePath = CGPath(
        roundedRect: plateRect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )

    // Plate fill + soft contact shadow.
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -canvas * 0.012),
        blur: canvas * 0.04,
        color: srgb(0, 0, 0, 0.22)
    )
    context.addPath(platePath)
    context.setFillColor(bottomColor)
    context.fillPath()
    context.restoreGState()

    // Vertical graphite gradient inside the plate.
    let backgroundGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [topColor, bottomColor] as CFArray,
        locations: [0, 1]
    )!
    context.saveGState()
    context.addPath(platePath)
    context.clip()
    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: 0, y: plateRect.maxY),
        end: CGPoint(x: 0, y: plateRect.minY),
        options: []
    )
    context.restoreGState()

    // Top-edge highlight.
    let highlightGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [srgb(1, 1, 1, 0.14), srgb(1, 1, 1, 0)] as CFArray,
        locations: [0, 1]
    )!
    context.saveGState()
    context.addPath(platePath)
    context.clip()
    context.drawLinearGradient(
        highlightGradient,
        start: CGPoint(x: 0, y: plateRect.maxY),
        end: CGPoint(x: 0, y: plateRect.maxY - plateSide * 0.30),
        options: []
    )
    context.restoreGState()

    // Sleeve-handle glyph: ••• + left-pointing triangle.
    let glyphWidth = plateSide * glyphFraction(forPixelSize: pixelSize)
    let unit = glyphWidth / 22.5
    let dotDiameter = 3 * unit
    let dotGap = 2.5 * unit
    let groupGap = 2.5 * unit
    let triangleWidth = 6 * unit
    let triangleHeight = 8 * unit
    let dotsWidth = dotDiameter * 3 + dotGap * 2
    let startX = (canvas - glyphWidth) / 2
    let centerY = canvas / 2

    let glyphPath = CGMutablePath()
    for index in 0 ..< 3 {
        let dotX = startX + CGFloat(index) * (dotDiameter + dotGap)
        glyphPath.addEllipse(in: CGRect(
            x: dotX,
            y: centerY - dotDiameter / 2,
            width: dotDiameter,
            height: dotDiameter
        ))
    }
    let triangleX = startX + dotsWidth + groupGap
    let triangleBottom = centerY - triangleHeight / 2
    glyphPath.move(to: CGPoint(x: triangleX, y: centerY))
    glyphPath.addLine(to: CGPoint(x: triangleX + triangleWidth, y: triangleBottom))
    glyphPath.addLine(to: CGPoint(x: triangleX + triangleWidth, y: triangleBottom + triangleHeight))
    glyphPath.closeSubpath()

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -plateSide * 0.006),
        blur: plateSide * 0.015,
        color: srgb(0, 0, 0, 0.30)
    )
    context.addPath(glyphPath)
    context.setFillColor(glyphColor)
    context.fillPath()
    context.restoreGState()

    return context.makeImage()!
}

let appIconSet = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Sleev/Resources/Assets.xcassets/AppIcon.appiconset")

guard FileManager.default.fileExists(atPath: appIconSet.path) else {
    fputs("error: \(appIconSet.path) not found — run from the repo root.\n", stderr)
    exit(1)
}

let contentsJSON = """
{
  "images" : [
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16.png", "scale" : "1x" },
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_32.png", "scale" : "2x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32.png", "scale" : "1x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_64.png", "scale" : "2x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128.png", "scale" : "1x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_256.png", "scale" : "2x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256.png", "scale" : "1x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_512.png", "scale" : "2x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512.png", "scale" : "1x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_1024.png", "scale" : "2x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}

"""

do {
    for size in pixelSizes {
        let image = renderIcon(pixelSize: size)
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            fputs("error: failed to encode icon_\(size).png\n", stderr)
            exit(1)
        }
        try data.write(to: appIconSet.appendingPathComponent("icon_\(size).png"))
        print("wrote icon_\(size).png (\(size)x\(size))")
    }
    try contentsJSON.write(
        to: appIconSet.appendingPathComponent("Contents.json"),
        atomically: true,
        encoding: .utf8
    )
    print("wrote Contents.json")
} catch {
    fputs("error: \(error)\n", stderr)
    exit(1)
}
