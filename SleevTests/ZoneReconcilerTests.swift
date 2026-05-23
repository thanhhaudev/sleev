@testable import Sleev
import XCTest

final class ZoneReconcilerTests: XCTestCase {
    /// Builds a 16x16 item whose frame is horizontally centered on `midX`.
    private func item(id: String, midX: CGFloat) -> MenubarItem {
        MenubarItem(
            id: id, bundleID: nil, displayName: id, icon: nil,
            frame: CGRect(x: midX - 8, y: 4, width: 16, height: 16),
            zone: .visible, isControllable: true
        )
    }

    func test_itemLeftOfSeparator_isSleeved() {
        let zones = ZoneReconciler.reconciledZones(
            items: [item(id: "a", midX: 300)],
            separatorBoundaryX: 500,
            screenXRange: 0 ... 1000
        )
        XCTAssertEqual(zones["a"], .sleeved)
    }

    func test_itemRightOfSeparator_isVisible() {
        let zones = ZoneReconciler.reconciledZones(
            items: [item(id: "a", midX: 700)],
            separatorBoundaryX: 500,
            screenXRange: 0 ... 1000
        )
        XCTAssertEqual(zones["a"], .visible)
    }

    func test_itemOutsideScreen_isOmitted() {
        let zones = ZoneReconciler.reconciledZones(
            items: [item(id: "a", midX: 1500)],
            separatorBoundaryX: 500,
            screenXRange: 0 ... 1000
        )
        XCTAssertNil(zones["a"])
    }

    func test_mixedItems_omitsOnlyOffScreen() {
        let zones = ZoneReconciler.reconciledZones(
            items: [
                item(id: "left", midX: 200),
                item(id: "right", midX: 800),
                item(id: "offscreen", midX: 1500)
            ],
            separatorBoundaryX: 500,
            screenXRange: 0 ... 1000
        )
        XCTAssertEqual(zones, ["left": .sleeved, "right": .visible])
    }

    func test_emptyItems_returnsEmpty() {
        let zones = ZoneReconciler.reconciledZones(
            items: [],
            separatorBoundaryX: 500,
            screenXRange: 0 ... 1000
        )
        XCTAssertTrue(zones.isEmpty)
    }

    func test_separatorOnSecondaryDisplay_classifiesByThatDisplaysRange() {
        // A second display sitting to the right of the primary: x 1000...2920.
        // The separator and its icons live entirely in that range; the fix
        // must classify them without any primary-display coordinate math.
        let zones = ZoneReconciler.reconciledZones(
            items: [
                item(id: "sleeved", midX: 1400),
                item(id: "visible", midX: 2500),
                item(id: "onPrimary", midX: 400)
            ],
            separatorBoundaryX: 1960,
            screenXRange: 1000 ... 2920
        )
        XCTAssertEqual(zones["sleeved"], .sleeved)
        XCTAssertEqual(zones["visible"], .visible)
        XCTAssertNil(zones["onPrimary"], "items on another display keep their stored zone")
    }
}
