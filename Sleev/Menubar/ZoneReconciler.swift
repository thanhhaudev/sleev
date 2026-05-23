import CoreGraphics

/// Derives each menu bar item's `Zone` from its horizontal position relative
/// to the sleev separator. Zone membership — whether an icon sits left of the
/// separator — is a purely horizontal decision, so no vertical coordinate
/// conversion is involved. Used to reconcile the popover with manual ⌘-drag
/// rearrangement of the menu bar.
enum ZoneReconciler {
    /// Returns a zone for each item whose horizontal midpoint lies within
    /// `screenXRange` — the x-extent of the display that holds the separator.
    /// Items on another display fall outside the range and are omitted, so the
    /// caller keeps their stored zone.
    ///
    /// `separatorBoundaryX` and every `item.frame` must be screen-global x
    /// values. The x-axis is identical between AppKit and the Accessibility
    /// API, so values from either space may be compared directly.
    ///
    /// The caller passes the separator's right edge (`frame.maxX`) rather
    /// than its center, because the right edge is stable across the
    /// expanded/collapsed states — when collapsed the separator grows
    /// leftward (pushing icons off-screen) while its right edge stays
    /// anchored at the user-intended boundary.
    static func reconciledZones(
        items: [MenubarItem],
        separatorBoundaryX: CGFloat,
        screenXRange: ClosedRange<CGFloat>
    ) -> [MenubarItem.ID: Zone] {
        var result: [MenubarItem.ID: Zone] = [:]
        for item in items {
            let midX = item.frame.midX
            guard screenXRange.contains(midX) else { continue }
            result[item.id] = midX < separatorBoundaryX ? .sleeved : .visible
        }
        return result
    }
}
