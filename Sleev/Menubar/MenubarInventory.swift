import AppKit
import Combine
import Foundation

@MainActor
public final class MenubarInventory: ObservableObject {
    @Published public private(set) var items: [MenubarItem] = []
    @Published public private(set) var outOfSyncItems: [MenubarItem] = []
    /// True until the first `apply(liveItems:)` call. Lets the UI show a
    /// loading state while the initial enumeration is running, instead of
    /// flashing the empty state.
    @Published public private(set) var isLoading: Bool = true

    public var controllableItems: [MenubarItem] {
        items.filter(\.isControllable)
    }

    public var systemItems: [MenubarItem] {
        items.filter { !$0.isControllable }
    }

    private let store: ZoneStore

    public init(store: ZoneStore) {
        self.store = store
    }

    /// Apply a fresh enumeration result. `actualZones` lets callers indicate where
    /// each item physically sits (visible vs sleeved), which the inventory compares
    /// against the persisted intent to flag out-of-sync items. When `actualZones`
    /// is empty/missing an entry, the inventory assumes the item is at its persisted zone.
    public func apply(
        liveItems: [MenubarItem],
        actualZones: [String: Zone] = [:]
    ) {
        var nextItems: [MenubarItem] = []
        var oos: [MenubarItem] = []
        for var item in liveItems {
            let intent = store.zone(forItemID: item.id)
            item.zone = intent
            nextItems.append(item)
            store.set(zone: intent, forItemID: item.id) // refresh lastSeen
            if let actual = actualZones[item.id], actual != intent {
                oos.append(item)
            }
        }
        items = nextItems
        outOfSyncItems = oos
        isLoading = false
    }

    public func setZone(_ zone: Zone, forItemID id: String) {
        store.set(zone: zone, forItemID: id)
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].zone = zone
        }
    }
}
