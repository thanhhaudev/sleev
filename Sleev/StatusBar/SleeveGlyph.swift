import AppKit

enum SleeveGlyph {
    /// Returns the smallest size that contains the full glyph at the given height
    /// without clipping. Width is derived from the glyph's intrinsic aspect ratio.
    static func naturalSize(forHeight height: CGFloat) -> NSSize {
        let unit = height / 14.0
        let dotDiameter = 3.0 * unit
        let dotGap = 2.5 * unit
        let triWidth = 6.0 * unit
        let groupGap = dotGap
        let dotsTotalWidth = dotDiameter * 3 + dotGap * 2
        let totalWidth = dotsTotalWidth + groupGap + triWidth
        // Add 1-unit padding on each side so anti-aliasing has room to breathe.
        return NSSize(width: ceil(totalWidth + 2 * unit), height: height)
    }

    /// When `wrapped` is true, adds pill padding (7pt horizontal + 2pt vertical on each side).
    static func naturalSize(forHeight height: CGFloat, wrapped: Bool) -> NSSize {
        let glyph = naturalSize(forHeight: height)
        guard wrapped else { return glyph }
        return NSSize(width: glyph.width + 14, height: glyph.height + 4)
    }

    static func image(
        height: CGFloat,
        color: NSColor,
        trianglePointsLeft: Bool = true,
        wrapped: Bool = false
    ) -> NSImage {
        let outerSize = naturalSize(forHeight: height, wrapped: wrapped)
        return NSImage(size: outerSize, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            let contentRect = wrapped ? drawPill(in: rect, context: context) : rect
            drawGlyph(in: contentRect, color: color, trianglePointsLeft: trianglePointsLeft, context: context)
            return true
        }
    }

    // MARK: - Private helpers

    /// Draws the pill background and border; returns the inner content rect for the glyph.
    private static func drawPill(in rect: CGRect, context: CGContext) -> CGRect {
        let pillRect = rect.insetBy(dx: 0.25, dy: 0.25)
        let pillPath = CGPath(roundedRect: pillRect, cornerWidth: 5, cornerHeight: 5, transform: nil)

        context.addPath(pillPath)
        NSColor.labelColor.withAlphaComponent(0.06).setFill()
        context.fillPath()

        context.addPath(pillPath)
        context.setLineWidth(0.5)
        NSColor.labelColor.withAlphaComponent(0.10).setStroke()
        context.strokePath()

        return rect.insetBy(dx: 7, dy: 2)
    }

    /// Draws the `•••◀` glyph inside `contentRect`.
    private static func drawGlyph(
        in contentRect: CGRect,
        color: NSColor,
        trianglePointsLeft: Bool,
        context: CGContext
    ) {
        color.setFill()

        let unit = contentRect.height / 14.0
        let dotDiameter = 3.0 * unit
        let dotGap = 2.5 * unit
        let triHeight = 8.0 * unit
        let triWidth = 6.0 * unit
        let groupGap = dotGap

        let dotsTotalWidth = dotDiameter * 3 + dotGap * 2
        let totalWidth = dotsTotalWidth + groupGap + triWidth
        let startX = contentRect.minX + (contentRect.width - totalWidth) / 2
        let dotY = contentRect.minY + (contentRect.height - dotDiameter) / 2

        for index in 0 ..< 3 {
            let dotX = startX + CGFloat(index) * (dotDiameter + dotGap)
            context.fillEllipse(in: CGRect(x: dotX, y: dotY, width: dotDiameter, height: dotDiameter))
        }

        let triX = startX + dotsTotalWidth + groupGap
        let triY = contentRect.minY + (contentRect.height - triHeight) / 2
        context.beginPath()
        if trianglePointsLeft {
            context.move(to: CGPoint(x: triX, y: triY + triHeight / 2))
            context.addLine(to: CGPoint(x: triX + triWidth, y: triY))
            context.addLine(to: CGPoint(x: triX + triWidth, y: triY + triHeight))
        } else {
            context.move(to: CGPoint(x: triX + triWidth, y: triY + triHeight / 2))
            context.addLine(to: CGPoint(x: triX, y: triY))
            context.addLine(to: CGPoint(x: triX, y: triY + triHeight))
        }
        context.closePath()
        context.fillPath()
    }
}
