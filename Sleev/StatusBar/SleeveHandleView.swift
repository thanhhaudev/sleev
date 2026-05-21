import AppKit
import QuartzCore

/// Layer-backed NSView that renders the `•••◀` sleeve handle with a 180° rotation
/// animation on the triangle when `pointsLeft` changes.
final class SleeveHandleView: NSView {
    private let pillLayer = CAShapeLayer()
    private let dotsLayer = CAShapeLayer()
    private let triangleLayer = CAShapeLayer()
    private var currentAngle: CGFloat = 0

    var showsPill = true {
        didSet { if oldValue != showsPill { needsLayout = true } }
    }

    var showsDots = true {
        didSet { if oldValue != showsDots { needsLayout = true } }
    }

    var showsChevron = true {
        didSet { if oldValue != showsChevron { needsLayout = true } }
    }

    /// When `false`, the triangle is rotated 180° (points right).
    var pointsLeft: Bool = true {
        didSet {
            guard oldValue != pointsLeft else { return }
            applyTriangleTransform(animated: true)
        }
    }

    /// When `true`, the triangle points down — shown while the popover is
    /// open. Overrides `pointsLeft`.
    var pointsDown: Bool = false {
        didSet {
            guard oldValue != pointsDown else { return }
            applyTriangleTransform(animated: true)
        }
    }

    override var intrinsicContentSize: NSSize {
        SleeveGlyph.naturalSize(
            forHeight: 14, showsPill: showsPill, showsDots: showsDots, showsChevron: showsChevron
        )
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
        let appearance = effectiveAppearance
        let fgColor = NSColor.labelColor.cgColor(for: appearance)

        if showsPill {
            layoutPillLayer(in: rect, appearance: appearance)
        } else {
            pillLayer.path = nil
        }

        let contentRect = showsPill ? rect.insetBy(dx: 7, dy: 2) : rect
        let unit = contentRect.height / 14.0
        let dotDiameter = 3.0 * unit
        let dotGap = 2.5 * unit
        let triWidth = 6.0 * unit
        let groupGap = dotGap
        let dotsTotalWidth = dotDiameter * 3 + dotGap * 2

        var totalWidth: CGFloat = 0
        if showsDots { totalWidth += dotsTotalWidth }
        if showsChevron { totalWidth += triWidth }
        if showsDots, showsChevron { totalWidth += groupGap }
        let startX = contentRect.minX + (contentRect.width - totalWidth) / 2

        if showsDots {
            layoutDotsLayer(
                startX: startX, diameter: dotDiameter, gap: dotGap,
                contentRect: contentRect, color: fgColor
            )
        } else {
            dotsLayer.path = nil
        }

        if showsChevron {
            let triX = startX + (showsDots ? dotsTotalWidth + groupGap : 0)
            layoutChevronLayer(
                originX: triX, width: triWidth,
                contentRect: contentRect, unit: unit, color: fgColor
            )
        } else {
            triangleLayer.path = nil
        }
    }

    private func layoutPillLayer(in rect: CGRect, appearance: NSAppearance) {
        let pillRect = rect.insetBy(dx: 0.5, dy: 0.5)
        pillLayer.path = CGPath(roundedRect: pillRect, cornerWidth: 5, cornerHeight: 5, transform: nil)
        pillLayer.fillColor = NSColor.labelColor.withAlphaComponent(0.08).cgColor(for: appearance)
        pillLayer.strokeColor = NSColor.labelColor.withAlphaComponent(0.30).cgColor(for: appearance)
        pillLayer.lineWidth = 1.0
    }

    private func layoutDotsLayer(
        startX: CGFloat,
        diameter: CGFloat,
        gap: CGFloat,
        contentRect: CGRect,
        color: CGColor
    ) {
        let dotY = contentRect.minY + (contentRect.height - diameter) / 2
        let path = CGMutablePath()
        for index in 0 ..< 3 {
            let dotX = startX + CGFloat(index) * (diameter + gap)
            path.addEllipse(in: CGRect(x: dotX, y: dotY, width: diameter, height: diameter))
        }
        dotsLayer.path = path
        dotsLayer.fillColor = color
    }

    private func layoutChevronLayer(
        originX: CGFloat,
        width: CGFloat,
        contentRect: CGRect,
        unit: CGFloat,
        color: CGColor
    ) {
        let triHeight = 8.0 * unit
        let triY = contentRect.minY + (contentRect.height - triHeight) / 2
        let halfWidth = width / 2
        let halfHeight = triHeight / 2
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -halfWidth, y: 0))
        path.addLine(to: CGPoint(x: halfWidth, y: -halfHeight))
        path.addLine(to: CGPoint(x: halfWidth, y: halfHeight))
        path.closeSubpath()
        triangleLayer.path = path
        triangleLayer.fillColor = color
        triangleLayer.bounds = CGRect(x: -halfWidth, y: -halfHeight, width: width, height: triHeight)
        triangleLayer.position = CGPoint(x: originX + width / 2, y: triY + triHeight / 2)
    }

    /// The triangle's target Z-rotation: pointing left (0), right (π), or down
    /// (π/2 while the popover is open). All three are in-plane rotations so the
    /// chevron rotates smoothly between them rather than flipping.
    private var targetAngle: CGFloat {
        if pointsDown {
            .pi / 2
        } else {
            pointsLeft ? 0 : .pi
        }
    }

    private func applyTriangleTransform(animated: Bool) {
        let newAngle = targetAngle
        if animated, currentAngle != newAngle {
            let anim = CABasicAnimation(keyPath: "transform.rotation.z")
            anim.duration = 0.20
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim.fromValue = currentAngle
            anim.toValue = newAngle
            triangleLayer.add(anim, forKey: "rotate")
        }
        currentAngle = newAngle
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        triangleLayer.transform = CATransform3DMakeRotation(newAngle, 0, 0, 1)
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
