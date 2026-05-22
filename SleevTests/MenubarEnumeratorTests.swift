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

    func test_excludedSystemItem_screenRecordingControl_isExcluded() {
        XCTAssertTrue(
            MenubarEnumerator.isExcludedSystemItem(
                bundleID: "com.apple.screencaptureui",
                axIdentifier: nil
            )
        )
    }

    func test_excludedSystemItem_cameraMicIndicator_isExcluded() {
        XCTAssertTrue(
            MenubarEnumerator.isExcludedSystemItem(
                bundleID: "com.apple.controlcenter",
                axIdentifier: "com.apple.menuextra.audiovideo"
            )
        )
    }

    func test_excludedSystemItem_clock_isExcluded() {
        XCTAssertTrue(
            MenubarEnumerator.isExcludedSystemItem(
                bundleID: "com.apple.controlcenter",
                axIdentifier: "com.apple.menuextra.clock"
            )
        )
    }

    func test_excludedSystemItem_controlCenterModule_isNotExcluded() {
        XCTAssertFalse(
            MenubarEnumerator.isExcludedSystemItem(
                bundleID: "com.apple.controlcenter",
                axIdentifier: "com.apple.menuextra.wifi"
            )
        )
    }

    func test_excludedSystemItem_thirdPartyApp_isNotExcluded() {
        XCTAssertFalse(
            MenubarEnumerator.isExcludedSystemItem(
                bundleID: "dev.kdrag0n.MacVirt",
                axIdentifier: nil
            )
        )
    }
}
