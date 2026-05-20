import AppKit

/// A small round dot rendered as the separator's visible content.
///
/// A status item needs visible content to be allocated a real slot in the menu
/// bar's status-item row. Without it the separator's window is orphaned at x=0
/// and widening it on collapse hides nothing. This dot is that content.
final class SeparatorDotView: NSView {
    private let diameter: CGFloat = 5

    override func draw(_: NSRect) {
        let rect = NSRect(
            x: bounds.midX - diameter / 2,
            y: bounds.midY - diameter / 2,
            width: diameter,
            height: diameter
        )
        NSColor.labelColor.withAlphaComponent(0.55).setFill()
        NSBezierPath(ovalIn: rect).fill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
