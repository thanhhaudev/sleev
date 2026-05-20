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
    /// IDs of items with a drag job in flight. Published so cards can show a
    /// spinner overlay while the drag runs.
    @Published public private(set) var inFlightIDs: Set<MenubarItem.ID> = []

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

    /// Apply a fresh enumeration result. Each item's `zone` is the *physical*
    /// zone the caller derived from the icon's on-screen position. The persisted
    /// intent in ZoneStore is compared against it to flag out-of-sync items
    /// (the icon isn't where the user last asked it to be).
    public func apply(liveItems: [MenubarItem]) {
        var oos: [MenubarItem] = []
        for item in liveItems {
            let intent = store.zone(forItemID: item.id)
            store.set(zone: intent, forItemID: item.id) // refresh lastSeen
            if item.zone != intent {
                oos.append(item)
            }
        }
        items = liveItems
        outOfSyncItems = oos
        isLoading = false
    }

    public func setZone(_ zone: Zone, forItemID id: String) {
        store.set(zone: zone, forItemID: id)
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].zone = zone
        }
    }

    public func setInFlight(_ id: MenubarItem.ID, _ active: Bool) {
        if active {
            inFlightIDs.insert(id)
        } else {
            inFlightIDs.remove(id)
        }
    }
}
