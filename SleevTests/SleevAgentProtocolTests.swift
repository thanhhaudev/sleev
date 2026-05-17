@testable import SleevCore
import XCTest

final class SleevAgentProtocolTests: XCTestCase {
    func test_xpcMachServiceNameIsStable() {
        XCTAssertEqual(SleevXPC.machServiceName, "com.thanhhaudev.sleev.Sleev.Agent.xpc")
    }

    func test_appGroupIdentifierIsStable() {
        XCTAssertEqual(SleevXPC.appGroupIdentifier, "group.com.thanhhaudev.sleev")
    }

    func test_axPermissionStateRawValues() {
        XCTAssertEqual(AXPermissionState.undetermined.rawValue, 0)
        XCTAssertEqual(AXPermissionState.denied.rawValue, 1)
        XCTAssertEqual(AXPermissionState.granted.rawValue, 2)
    }
}
