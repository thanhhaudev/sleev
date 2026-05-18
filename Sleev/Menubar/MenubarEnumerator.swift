import AppKit
import ApplicationServices
import Foundation
import SleevCore

/// Reads menubar extras from running applications via the Accessibility API.
/// The UI process must be granted Accessibility for this to return any results.
///
/// macOS 14+ does NOT expose Control Center's bundled items (Wi-Fi, Battery,
/// Sound, Display) through a single SystemUIServer enumeration point. Instead,
/// each app that owns a menubar extra exposes its own `AXExtrasMenuBar` attribute.
/// We enumerate all running apps, collect those extras, and mark Apple-owned items
/// as `isControllable = false`.
public final class MenubarEnumerator {
    public init() {}

    public func enumerate() -> [MenubarItem] {
        let ownBundleID = Bundle.main.bundleIdentifier
        var items: [MenubarItem] = []
        var seenIDs = Set<String>()
        for runApp in NSWorkspace.shared.runningApplications {
            if let runBundleID = runApp.bundleIdentifier, runBundleID == ownBundleID { continue }
            let appItems = enumerateExtras(for: runApp)
            for item in appItems where !seenIDs.contains(item.id) {
                seenIDs.insert(item.id)
                items.append(item)
            }
        }
        Log.accessibility.info(
            "Enumerator: found \(items.count) items: \(items.map(\.displayName).joined(separator: ", "), privacy: .public)"
        )
        return items
    }

    private func enumerateExtras(for runApp: NSRunningApplication) -> [MenubarItem] {
        let axApp = AXUIElementCreateApplication(runApp.processIdentifier)
        var extrasRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, "AXExtrasMenuBar" as CFString, &extrasRef) == .success,
              let ref = extrasRef
        else { return [] }

        // AXUIElement is a CF type; unsafeBitCast is required because
        // conditional cast (`as?`) is a compile-time error for CF types,
        // and `as!` triggers the force_cast lint rule.
        let extrasBar = unsafeBitCast(ref, to: AXUIElement.self)
        var childrenRef: CFTypeRef?
        AXUIElementCopyAttributeValue(extrasBar, kAXChildrenAttribute as CFString, &childrenRef)
        guard let elementsArray = childrenRef as? [AXUIElement] else { return [] }

        var items: [MenubarItem] = []
        for element in elementsArray {
            if let item = makeItem(from: element) {
                items.append(item)
            }
        }
        return items
    }

    private func makeItem(from element: AXUIElement) -> MenubarItem? {
        let owner = owningApp(of: element)
        let bundleID = owner?.bundleIdentifier
        let displayName = bestDisplayName(element: element, owner: owner, bundleID: bundleID)
        let frame = elementFrame(element) ?? .zero
        let isControllable = !(bundleID?.hasPrefix("com.apple.") ?? false)
        let id = bundleID ?? "name:\(displayName)"
        return MenubarItem(
            id: id,
            bundleID: bundleID,
            displayName: displayName,
            icon: lookupIcon(forBundleID: bundleID),
            frame: frame,
            zone: .visible,
            isControllable: isControllable
        )
    }

    private func bestDisplayName(
        element: AXUIElement,
        owner: NSRunningApplication?,
        bundleID: String?
    ) -> String {
        // 1. Use AX title if non-empty.
        if let axTitle = stringAttribute(element, kAXTitleAttribute), !axTitle.isEmpty {
            return axTitle
        }
        // 2. Fall back to the owning app's localized name.
        if let localized = owner?.localizedName, !localized.isEmpty {
            return localized
        }
        // 3. Last resort: last segment of the bundle ID.
        if let bundleID, let last = bundleID.split(separator: ".").last {
            return String(last).capitalized
        }
        return "(untitled)"
    }

    private func owningApp(of element: AXUIElement) -> NSRunningApplication? {
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success else { return nil }
        return NSRunningApplication(processIdentifier: pid)
    }

    private func stringAttribute(_ element: AXUIElement, _ name: String) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard result == .success else { return nil }
        return value as? String
    }

    private func elementFrame(_ element: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success
        else { return nil }
        guard let posRef = positionValue, let sizeRef = sizeValue else { return nil }
        // AXValue is a CF type; unsafeBitCast is required for the same reason as AXUIElement.
        let posAX = unsafeBitCast(posRef, to: AXValue.self)
        let sizeAX = unsafeBitCast(sizeRef, to: AXValue.self)
        var origin = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posAX, .cgPoint, &origin)
        AXValueGetValue(sizeAX, .cgSize, &size)
        return CGRect(origin: origin, size: size)
    }

    private func lookupIcon(forBundleID bundleID: String?) -> NSImage? {
        guard let bundleID,
              let bundleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: bundleURL.path)
        icon.size = NSSize(width: 16, height: 16)
        return icon
    }
}
