import CoreGraphics
import Foundation

enum CollapseLengthCalculator {
    /// The separator's width while expanded — the dot diameter plus a little
    /// breathing room.
    static func visibleSeparatorLength(forDotDiameter diameter: CGFloat) -> CGFloat {
        diameter + 2
    }

    static let minCollapseLength: CGFloat = 500
    static let maxCollapseLength: CGFloat = 4000
    static let buffer: CGFloat = 200

    static func collapseLength(forScreenWidth width: CGFloat) -> CGFloat {
        let raw = width + buffer
        return max(minCollapseLength, min(maxCollapseLength, raw))
    }
}
