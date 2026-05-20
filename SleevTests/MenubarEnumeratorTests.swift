@testable import Sleev
import XCTest

final class MenubarEnumeratorTests: XCTestCase {
    /// Integration test — requires the test runner to have Accessibility permission
    /// for at least one item to come back. Skips gracefully if no items found.
    func test_enumerateReturnsItems() throws {
        let enumerator = MenubarEnumerator()
        let items = enumerator.enumerate()
        try XCTSkipIf(items.isEmpty, "No menubar items returned; install a menubar app or grant AX")
        XCTAssertGreaterThan(items.count, 0)
    }

    /// Every enumerated item is exposed as controllable; whether macOS actually
    /// permits the drag is decided at drag time by the M4 DragSimulator.
    func test_allEnumeratedItemsAreControllable() {
        let enumerator = MenubarEnumerator()
        let items = enumerator.enumerate()
        for item in items {
            XCTAssertTrue(
                item.isControllable,
                "Every enumerated item should be controllable: \(item.displayName)"
            )
        }
    }
}
