import CoreGraphics
import SleevCore

/// Pure geometry for the sleeve trick: classifying an icon's physical zone and
/// translating a sleeve/unsleeve intent into drag endpoints.
enum DragGeometry {
    private static let targetOffset: CGFloat = 16

    /// An icon left of the separator's left edge is hidden on collapse
    /// (sleeved); otherwise it sits in the visible zone.
    static func physicalZone(forFrame frame: CGRect, separatorMinX: CGFloat?) -> Zone {
        guard let separatorMinX else { return .visible }
        return frame.midX < separatorMinX ? .sleeved : .visible
    }

    /// Sleeve targets land left of the separator; unsleeve targets land right
    /// of the handle, clearly inside the visible zone.
    static func endpoints(
        item: MenubarItem,
        targetZone: Zone,
        separatorFrame: CGRect?,
        handleFrame: CGRect?
    ) -> (source: CGPoint, target: CGPoint) {
        let source = CGPoint(x: item.frame.midX, y: item.frame.midY)
        let targetX: CGFloat = switch targetZone {
        case .sleeved: (separatorFrame?.minX ?? source.x) - targetOffset
        case .visible: (handleFrame?.maxX ?? source.x) + targetOffset
        }
        return (source, CGPoint(x: targetX, y: source.y))
    }
}
