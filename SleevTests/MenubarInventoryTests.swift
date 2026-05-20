@testable import Sleev
@testable import SleevCore
import XCTest

final class MenubarInventoryTests: XCTestCase {
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

    @MainActor
    func test_applyKeepsPhysicalZoneFromLiveItem() {
        let store = ZoneStore(defaults: defaults, clock: { Date() })
        let inventory = MenubarInventory(store: store)
        let live = [
            MenubarItem(
                id: "com.spotify.client", bundleID: "com.spotify.client",
                displayName: "Spotify", icon: nil,
                frame: .zero, zone: .sleeved, isControllable: true
            )
        ]
        inventory.apply(liveItems: live)
        XCTAssertEqual(
            inventory.items.first?.zone, .sleeved,
            "Inventory should keep the physical zone the caller provided"
        )
    }

    @MainActor
    func test_marksOutOfSyncWhenPhysicalDiffersFromIntent() {
        let store = ZoneStore(defaults: defaults, clock: { Date() })
        store.set(zone: .sleeved, forItemID: "com.spotify.client")
        let inventory = MenubarInventory(store: store)
        let live = [
            MenubarItem(
                id: "com.spotify.client", bundleID: "com.spotify.client",
                displayName: "Spotify", icon: nil,
                frame: .zero, zone: .visible, isControllable: true
            )
        ]
        inventory.apply(liveItems: live)
        XCTAssertTrue(
            inventory.outOfSyncItems.contains { $0.id == "com.spotify.client" },
            "Physically visible item with sleeved intent should be out of sync"
        )
    }

    @MainActor
    func test_uncontrollableItemsAreExposedSeparately() {
        let store = ZoneStore(defaults: defaults, clock: { Date() })
        let inventory = MenubarInventory(store: store)
        let live = [
            MenubarItem(
                id: "wifi", bundleID: "com.apple.controlcenter.wifi",
                displayName: "Wi-Fi", icon: nil,
                frame: .zero, zone: .visible, isControllable: false
            ),
            MenubarItem(
                id: "spotify", bundleID: "com.spotify.client",
                displayName: "Spotify", icon: nil,
                frame: .zero, zone: .visible, isControllable: true
            )
        ]
        inventory.apply(liveItems: live)
        XCTAssertEqual(inventory.controllableItems.count, 1)
        XCTAssertEqual(inventory.systemItems.count, 1)
    }
}
