@testable import Sleev
import XCTest

final class MenubarItemIDTests: XCTestCase {
    func test_singleExtra_usesBundleID() {
        let id = MenubarItemID.make(
            bundleID: "com.example.app",
            displayName: "Example",
            axIdentifier: "ignored-when-single",
            siblingCount: 1,
            index: 0
        )
        XCTAssertEqual(id, "com.example.app")
    }

    func test_singleExtra_nilBundleID_usesName() {
        let id = MenubarItemID.make(
            bundleID: nil,
            displayName: "Example",
            axIdentifier: nil,
            siblingCount: 1,
            index: 0
        )
        XCTAssertEqual(id, "name:Example")
    }

    func test_multipleExtras_withAXIdentifier_appendsIdentifier() {
        let id = MenubarItemID.make(
            bundleID: "com.apple.controlcenter",
            displayName: "Bluetooth",
            axIdentifier: "com.apple.menuextra.bluetooth",
            siblingCount: 5,
            index: 1
        )
        XCTAssertEqual(id, "com.apple.controlcenter::com.apple.menuextra.bluetooth")
    }

    func test_multipleExtras_emptyAXIdentifier_fallsBackToIndex() {
        let id = MenubarItemID.make(
            bundleID: "com.example.multi",
            displayName: "Second",
            axIdentifier: "",
            siblingCount: 2,
            index: 1
        )
        XCTAssertEqual(id, "com.example.multi::idx1")
    }

    func test_multipleExtras_nilAXIdentifier_fallsBackToIndex() {
        let id = MenubarItemID.make(
            bundleID: "com.example.multi",
            displayName: "First",
            axIdentifier: nil,
            siblingCount: 2,
            index: 0
        )
        XCTAssertEqual(id, "com.example.multi::idx0")
    }
}
