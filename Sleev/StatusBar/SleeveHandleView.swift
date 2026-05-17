import AppKit
import QuartzCore

/// Layer-backed NSView that renders the `•••◀` sleeve handle with a 180° rotation
/// animation on the triangle when `pointsLeft` changes.
final class SleeveHandleView: NSView {
    private let pillLayer = CAShapeLayer()
    private let dotsLayer = CAShapeLayer()
    private let triangleLayer = CAShapeLayer()

    /// When `false`, the triangle is rotated 180° (points right).
    var pointsLeft: Bool = true {
        didSet {
            guard oldValue != pointsLeft else { return }
            applyTriangleTransform(animated: true)
        }
    }

    override var intrinsicContentSize: NSSize {
        SleeveGlyph.naturalSize(forHeight: 14, wrapped: true)
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer = CALayer()
        layer?.addSublayer(pillLayer)
        layer?.addSublayer(dotsLayer)
        layer?.addSublayer(triangleLayer)
        applyTriangleTransform(animated: false)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func layout() {
        super.layout()
        rebuildLayers()
        applyTriangleTransform(animated: false)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        rebuildLayers()
    }

    // MARK: - Private

    private func rebuildLayers() {
        let rect = bounds
        let unitSize = (rect.height - 4) / 14.0
        let contentRect = rect.insetBy(dx: 7, dy: 2)

        let appearance = effectiveAppearance
        let fillColor = NSColor.labelColor.withAlphaComponent(0.06).cgColor(for: appearance)
        let strokeColor = NSColor.labelColor.withAlphaComponent(0.10).cgColor(for: appearance)
        let fgColor = NSColor.labelColor.cgColor(for: appearance)

        let pillRect = rect.insetBy(dx: 0.25, dy: 0.25)
        pillLayer.path = CGPath(roundedRect: pillRect, cornerWidth: 5, cornerHeight: 5, transform: nil)
        pillLayer.fillColor = fillColor
        pillLayer.strokeColor = strokeColor
        pillLayer.lineWidth = 0.5

        let dotDiameter = 3.0 * unitSize
        let dotGap = 2.5 * unitSize
        let triHeight = 8.0 * unitSize
        let triWidth = 6.0 * unitSize
        let groupGap = dotGap

        let dotsTotalWidth = dotDiameter * 3 + dotGap * 2
        let totalWidth = dotsTotalWidth + groupGap + triWidth
        let startX = contentRect.minX + (contentRect.width - totalWidth) / 2
        let dotY = contentRect.minY + (contentRect.height - dotDiameter) / 2

        let dotsPath = CGMutablePath()
        for index in 0 ..< 3 {
            let dotX = startX + CGFloat(index) * (dotDiameter + dotGap)
            dotsPath.addEllipse(in: CGRect(x: dotX, y: dotY, width: dotDiameter, height: dotDiameter))
        }
        dotsLayer.path = dotsPath
        dotsLayer.fillColor = fgColor

        let triX = startX + dotsTotalWidth + groupGap
        let triY = contentRect.minY + (contentRect.height - triHeight) / 2
        let triCenter = CGPoint(x: triX + triWidth / 2, y: triY + triHeight / 2)

        let halfWidth = triWidth / 2
        let halfHeight = triHeight / 2
        let trianglePath = CGMutablePath()
        trianglePath.move(to: CGPoint(x: -halfWidth, y: 0))
        trianglePath.addLine(to: CGPoint(x: halfWidth, y: -halfHeight))
        trianglePath.addLine(to: CGPoint(x: halfWidth, y: halfHeight))
        trianglePath.closeSubpath()

        triangleLayer.path = trianglePath
        triangleLayer.fillColor = fgColor
        triangleLayer.bounds = CGRect(x: -halfWidth, y: -halfHeight, width: triWidth, height: triHeight)
        triangleLayer.position = triCenter
    }

    private func applyTriangleTransform(animated: Bool) {
        let angle: CGFloat = pointsLeft ? 0 : .pi
        let newTransform = CATransform3DMakeRotation(angle, 0, 0, 1)

        if animated {
            let anim = CABasicAnimation(keyPath: "transform")
            anim.duration = 0.20
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim.fromValue = triangleLayer.presentation()?.transform ?? triangleLayer.transform
            anim.toValue = newTransform
            triangleLayer.add(anim, forKey: "rotate")
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        triangleLayer.transform = newTransform
        CATransaction.commit()
    }
}

private extension NSColor {
    func cgColor(for appearance: NSAppearance) -> CGColor {
        var resolved: CGColor!
        appearance.performAsCurrentDrawingAppearance {
            resolved = self.cgColor
        }
        return resolved
    }
}
