@testable import Sleev
import XCTest

final class OnboardingWindowControllerTests: XCTestCase {
    func test_windowStyleMaskExcludesClosable() throws {
        let controller = OnboardingWindowController()
        let window = try XCTUnwrap(controller.window)
        XCTAssertFalse(
            window.styleMask.contains(.closable),
            "Onboarding window must not have a close button (Bug 2A regression guard)"
        )
    }

    func test_windowStyleMaskIncludesTitled() throws {
        let controller = OnboardingWindowController()
        let window = try XCTUnwrap(controller.window)
        XCTAssertTrue(
            window.styleMask.contains(.titled),
            "Onboarding window must keep the titled style for traffic lights"
        )
    }
}
