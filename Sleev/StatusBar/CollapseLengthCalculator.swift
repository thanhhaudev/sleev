import CoreGraphics
import Foundation

enum CollapseLengthCalculator {
    /// The separator's width while expanded — wide enough to show the dot.
    static let visibleSeparatorLength: CGFloat = 8
    static let minCollapseLength: CGFloat = 500
    static let maxCollapseLength: CGFloat = 4000
    static let buffer: CGFloat = 200

    static func collapseLength(forScreenWidth width: CGFloat) -> CGFloat {
        let raw = width + buffer
        return max(minCollapseLength, min(maxCollapseLength, raw))
    }
}
