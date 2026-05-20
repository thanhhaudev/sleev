import AppKit
import Combine
import Foundation

@MainActor
public final class MenubarInventory: ObservableObject {
    @Published public private(set) var items: [MenubarItem] = []
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

    /// Apply a fresh enumeration result. Each item's `zone` is set from
    /// ZoneStore — the persisted intent — so the popover reflects what sleev
    /// last did, independent of the icon's on-screen position.
    public func apply(liveItems: [MenubarItem]) {
        items = liveItems.map { item in
            var copy = item
            copy.zone = store.zone(forItemID: item.id)
            store.set(zone: copy.zone, forItemID: item.id) // refresh lastSeen
            return copy
        }
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
