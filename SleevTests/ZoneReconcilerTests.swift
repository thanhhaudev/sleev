@testable import Sleev
import XCTest

final class ZoneReconcilerTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
    /// A small separator whose midX is 500.
    private let separator = CGRect(x: 496, y: 4, width: 8, height: 16)

    /// Builds a 16x16 item whose frame is centered on (midX, midY).
    private func item(id: String, midX: CGFloat, midY: CGFloat = 12) -> MenubarItem {
        MenubarItem(
            id: id, bundleID: nil, displayName: id, icon: nil,
            frame: CGRect(x: midX - 8, y: midY - 8, width: 16, height: 16),
            zone: .visible, isControllable: true
        )
    }

    // MARK: reconciledZones

    func test_itemLeftOfSeparator_isSleeved() {
        let zones = ZoneReconciler.reconciledZones(
            items: [item(id: "a", midX: 300)],
            separatorFrame: separator,
            screenFrame: screen
        )
        XCTAssertEqual(zones["a"], .sleeved)
    }

    func test_itemRightOfSeparator_isVisible() {
        let zones = ZoneReconciler.reconciledZones(
            items: [item(id: "a", midX: 700)],
            separatorFrame: separator,
            screenFrame: screen
        )
        XCTAssertEqual(zones["a"], .visible)
    }

    func test_itemOutsideScreen_isOmitted() {
        let zones = ZoneReconciler.reconciledZones(
            items: [item(id: "a", midX: 1500)],
            separatorFrame: separator,
            screenFrame: screen
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
            separatorFrame: separator,
            screenFrame: screen
        )
        XCTAssertEqual(zones, ["left": .sleeved, "right": .visible])
    }

    func test_emptyItems_returnsEmpty() {
        let zones = ZoneReconciler.reconciledZones(
            items: [],
            separatorFrame: separator,
            screenFrame: screen
        )
        XCTAssertTrue(zones.isEmpty)
    }

    // MARK: appKitRectToAX

    func test_appKitRectToAX_flipsYAboutPrimaryHeight() {
        let result = ZoneReconciler.appKitRectToAX(
            CGRect(x: 10, y: 0, width: 5, height: 20),
            primaryDisplayHeight: 100
        )
        XCTAssertEqual(result, CGRect(x: 10, y: 80, width: 5, height: 20))
    }

    func test_appKitRectToAX_leavesXAndSizeUnchanged() {
        let result = ZoneReconciler.appKitRectToAX(
            CGRect(x: 42, y: 30, width: 8, height: 16),
            primaryDisplayHeight: 900
        )
        XCTAssertEqual(result.origin.x, 42)
        XCTAssertEqual(result.width, 8)
        XCTAssertEqual(result.height, 16)
    }
}
