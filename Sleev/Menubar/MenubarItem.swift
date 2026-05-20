import AppKit
import Foundation

public enum Zone: String, Codable, Hashable, Sendable {
    case visible
    case sleeved
}

public struct MenubarItem: Identifiable, Hashable {
    public let id: String
    public let bundleID: String?
    public let displayName: String
    public let icon: NSImage?
    public var frame: CGRect
    public var zone: Zone
    public var isControllable: Bool

    public init(
        id: String,
        bundleID: String?,
        displayName: String,
        icon: NSImage?,
        frame: CGRect,
        zone: Zone,
        isControllable: Bool
    ) {
        self.id = id
        self.bundleID = bundleID
        self.displayName = displayName
        self.icon = icon
        self.frame = frame
        self.zone = zone
        self.isControllable = isControllable
    }

    /// NSImage isn't Hashable, so hash on identity-derived fields only.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(bundleID)
        hasher.combine(displayName)
        hasher.combine(zone)
        hasher.combine(isControllable)
    }

    public static func == (lhs: MenubarItem, rhs: MenubarItem) -> Bool {
        lhs.id == rhs.id
            && lhs.bundleID == rhs.bundleID
            && lhs.displayName == rhs.displayName
            && lhs.frame == rhs.frame
            && lhs.zone == rhs.zone
            && lhs.isControllable == rhs.isControllable
    }
}
