import CoreGraphics
import SleevCore

/// Pure geometry for the sleeve trick: translating a sleeve/unsleeve intent
/// into synthetic-drag endpoints.
enum DragGeometry {
    private static let targetOffset: CGFloat = 16

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
