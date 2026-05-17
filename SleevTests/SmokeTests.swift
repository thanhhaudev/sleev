import XCTest
@testable import SleevCore

final class SmokeTests: XCTestCase {
    func test_sleevCoreVersionIsExposed() {
        XCTAssertEqual(SleevCore.version, "0.1.0")
    }
}
