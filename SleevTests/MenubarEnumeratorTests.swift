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

    /// Sanity: Apple-owned items (if present) should be marked not-controllable.
    func test_appleOwnedItemsAreNotControllable() {
        let enumerator = MenubarEnumerator()
        let items = enumerator.enumerate()
        let appleItems = items.filter { $0.bundleID?.hasPrefix("com.apple.") == true }
        for item in appleItems {
            XCTAssertFalse(
                item.isControllable,
                "Apple-owned item should not be controllable: \(item.displayName)"
            )
        }
    }
}
