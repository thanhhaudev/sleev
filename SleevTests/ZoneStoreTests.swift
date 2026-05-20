@testable import Sleev
@testable import SleevCore
import XCTest

final class ZoneStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "com.thanhhaudev.sleev.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func test_setAndGetZone() {
        let store = ZoneStore(defaults: defaults, clock: { Date() })
        store.set(zone: .sleeved, forItemID: "com.spotify.client")
        XCTAssertEqual(store.zone(forItemID: "com.spotify.client"), .sleeved)
    }

    func test_unknownItemReturnsVisible() {
        let store = ZoneStore(defaults: defaults, clock: { Date() })
        XCTAssertEqual(store.zone(forItemID: "com.unknown"), .visible)
    }

    func test_recordsLastSeenAtSetTime() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let store = ZoneStore(defaults: defaults, clock: { fixedDate })
        store.set(zone: .sleeved, forItemID: "com.spotify.client")
        XCTAssertEqual(store.lastSeen(forItemID: "com.spotify.client"), fixedDate)
    }

    func test_evictOrphansRemovesItemsNotSeenForFifteenDays() {
        var currentDate = Date(timeIntervalSince1970: 1_700_000_000)
        let store = ZoneStore(defaults: defaults, clock: { currentDate })
        store.set(zone: .sleeved, forItemID: "com.old.app")
        currentDate = currentDate.addingTimeInterval(60 * 60 * 24 * 15) // +15 days
        store.evictOrphans(maxAgeSeconds: 60 * 60 * 24 * 14) // 14-day TTL
        XCTAssertEqual(
            store.zone(forItemID: "com.old.app"),
            .visible,
            "Item older than TTL should be evicted; default zone is .visible"
        )
    }

    func test_evictOrphansKeepsRecentlySeenItems() {
        var currentDate = Date(timeIntervalSince1970: 1_700_000_000)
        let store = ZoneStore(defaults: defaults, clock: { currentDate })
        store.set(zone: .sleeved, forItemID: "com.recent.app")
        currentDate = currentDate.addingTimeInterval(60 * 60 * 24 * 10) // +10 days
        store.evictOrphans(maxAgeSeconds: 60 * 60 * 24 * 14)
        XCTAssertEqual(store.zone(forItemID: "com.recent.app"), .sleeved)
    }
}
