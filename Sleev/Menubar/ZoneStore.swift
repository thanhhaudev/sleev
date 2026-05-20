import Foundation
import SleevCore

/// Persists each menubar item's intended `Zone` plus a `lastSeen` timestamp.
/// Items not seen for the configured TTL (default 14 days) are evicted to keep
/// the store from accumulating uninstalled-app entries forever.
public final class ZoneStore {
    public typealias Clock = () -> Date

    private let defaults: UserDefaults
    private let clock: Clock
    private let zoneKey = "sleev.zones.itemZones"
    private let lastSeenKey = "sleev.zones.lastSeen"

    public init(defaults: UserDefaults = AppGroupDefaults.shared(), clock: @escaping Clock = Date.init) {
        self.defaults = defaults
        self.clock = clock
    }

    public func zone(forItemID id: String) -> Zone {
        let raw = (defaults.dictionary(forKey: zoneKey)?[id] as? String) ?? Zone.visible.rawValue
        return Zone(rawValue: raw) ?? .visible
    }

    public func set(zone: Zone, forItemID id: String) {
        var zones = defaults.dictionary(forKey: zoneKey) as? [String: String] ?? [:]
        var lastSeen = defaults.dictionary(forKey: lastSeenKey) as? [String: TimeInterval] ?? [:]
        zones[id] = zone.rawValue
        lastSeen[id] = clock().timeIntervalSince1970
        defaults.set(zones, forKey: zoneKey)
        defaults.set(lastSeen, forKey: lastSeenKey)
    }

    public func lastSeen(forItemID id: String) -> Date? {
        guard let timestamps = defaults.dictionary(forKey: lastSeenKey) as? [String: TimeInterval],
              let value = timestamps[id] else { return nil }
        return Date(timeIntervalSince1970: value)
    }

    public func evictOrphans(maxAgeSeconds: TimeInterval) {
        let now = clock().timeIntervalSince1970
        var zones = defaults.dictionary(forKey: zoneKey) as? [String: String] ?? [:]
        var lastSeen = defaults.dictionary(forKey: lastSeenKey) as? [String: TimeInterval] ?? [:]
        for (id, seenAt) in lastSeen where now - seenAt > maxAgeSeconds {
            zones.removeValue(forKey: id)
            lastSeen.removeValue(forKey: id)
        }
        defaults.set(zones, forKey: zoneKey)
        defaults.set(lastSeen, forKey: lastSeenKey)
    }
}
