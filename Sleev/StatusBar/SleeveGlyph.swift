import AppKit

enum SleeveGlyph {
    static func image(size: NSSize, color: NSColor, trianglePointsLeft: Bool = true) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            color.setFill()

            // Scale the layout proportionally to the requested size.
            let unit = rect.height / 14.0
            let dotDiameter = 3.0 * unit
            let dotGap = 2.5 * unit
            let triHeight = 8.0 * unit
            let triWidth = 6.0 * unit
            let groupGap = 5.0 * unit

            let dotsTotalWidth = dotDiameter * 3 + dotGap * 2
            let totalWidth = dotsTotalWidth + groupGap + triWidth
            let startX = (rect.width - totalWidth) / 2
            let dotY = (rect.height - dotDiameter) / 2

            guard let context = NSGraphicsContext.current?.cgContext else { return false }

            for index in 0 ..< 3 {
                let dotX = startX + CGFloat(index) * (dotDiameter + dotGap)
                context.fillEllipse(in: CGRect(x: dotX, y: dotY, width: dotDiameter, height: dotDiameter))
            }

            let triX = startX + dotsTotalWidth + groupGap
            let triY = (rect.height - triHeight) / 2
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
            return true
        }
    }
}
