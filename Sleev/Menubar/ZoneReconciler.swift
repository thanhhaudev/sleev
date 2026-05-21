import CoreGraphics

/// Derives each menu bar item's `Zone` from its on-screen position relative
/// to the sleev separator, and converts AppKit rects into the coordinate
/// space the enumerated item frames use. Used to reconcile the popover with
/// manual ⌘-drag rearrangement of the menu bar.
enum ZoneReconciler {
    /// Returns a zone for each item whose frame midpoint lies inside
    /// `screenFrame`. Items outside it — on another display's menu bar — are
    /// omitted, so the caller keeps their stored zone.
    ///
    /// All three rects must be in the Accessibility API's top-left-origin
    /// coordinate space (the space of `MenubarItem.frame`).
    static func reconciledZones(
        items: [MenubarItem],
        separatorFrame: CGRect,
        screenFrame: CGRect
    ) -> [MenubarItem.ID: Zone] {
        var result: [MenubarItem.ID: Zone] = [:]
        for item in items {
            let midpoint = CGPoint(x: item.frame.midX, y: item.frame.midY)
            guard screenFrame.contains(midpoint) else { continue }
            result[item.id] = item.frame.midX < separatorFrame.midX ? .sleeved : .visible
        }
        return result
    }

    /// Converts an AppKit (bottom-left origin) global rect into the
    /// Accessibility API's top-left-origin space. Y is flipped about the
    /// primary display's height; X and size are unchanged.
    static func appKitRectToAX(_ rect: CGRect, primaryDisplayHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryDisplayHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}
