import XCTest
@testable import SleevCore

final class SleevAgentProtocolTests: XCTestCase {
    func test_xpcMachServiceNameIsStable() {
        XCTAssertEqual(SleevXPC.machServiceName, "dev.sleev.Sleev.Agent.xpc")
    }

    func test_appGroupIdentifierIsStable() {
        XCTAssertEqual(SleevXPC.appGroupIdentifier, "group.dev.sleev")
    }

    func test_axPermissionStateRawValues() {
        XCTAssertEqual(AXPermissionState.undetermined.rawValue, 0)
        XCTAssertEqual(AXPermissionState.denied.rawValue, 1)
        XCTAssertEqual(AXPermissionState.granted.rawValue, 2)
    }
}
