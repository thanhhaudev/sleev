import CoreGraphics
import Foundation

enum CollapseLengthCalculator {
    static let visibleSeparatorLength: CGFloat = 1
    static let minCollapseLength: CGFloat = 500
    static let maxCollapseLength: CGFloat = 4000
    static let buffer: CGFloat = 200

    static func collapseLength(forScreenWidth width: CGFloat) -> CGFloat {
        let raw = width + buffer
        return max(minCollapseLength, min(maxCollapseLength, raw))
    }
}
