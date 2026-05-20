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
    func test_applySetsZoneFromStore() {
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
        XCTAssertEqual(
            inventory.items.first?.zone, .sleeved,
            "Inventory should set each item's zone from ZoneStore, ignoring the live item's zone"
        )
    }

    @MainActor
    func test_applyDefaultsToVisibleWhenItemAbsentFromStore() {
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
            inventory.items.first?.zone, .visible,
            "An item absent from ZoneStore should default to .visible"
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
