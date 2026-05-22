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
/// We enumerate all running apps and collect those extras.
public final class MenubarEnumerator {
    /// AXIdentifiers of menu bar extras macOS pins in place. They cannot be
    /// dragged, so the popover omits them. The control-center and clock values
    /// were captured by an earlier diagnostic run; `audiovideo` is the
    /// camera/microphone in-use indicator, confirmed by the diagnostic run for
    /// the system-indicator-exclusion fix.
    private static let excludedAXIdentifiers: Set<String> = [
        "com.apple.menuextra.controlcenter",
        "com.apple.menuextra.clock",
        "com.apple.menuextra.audiovideo"
    ]

    /// Bundle identifiers whose every menu bar extra the popover omits.
    /// `com.apple.screencaptureui` owns the transient screen-recording stop
    /// control, which is system-pinned and not user-draggable.
    private static let excludedBundleIDs: Set<String> = [
        "com.apple.screencaptureui"
    ]

    /// True for system menu bar items the popover must never list: macOS-pinned
    /// extras (Control Center, clock), the camera/microphone in-use indicator,
    /// and the screen-recording stop control. None can be repositioned by the
    /// user, so listing them as cards would only mislead.
    static func isExcludedSystemItem(bundleID: String?, axIdentifier: String?) -> Bool {
        if let axIdentifier, excludedAXIdentifiers.contains(axIdentifier) {
            return true
        }
        if let bundleID, excludedBundleIDs.contains(bundleID) {
            return true
        }
        return false
    }

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
            "Enumerator: found \(items.count) items: \(items.map { "\($0.displayName) [\($0.id)]" }.joined(separator: ", "), privacy: .public)"
        )
        return items
    }

    private func enumerateExtras(for runApp: NSRunningApplication) -> [MenubarItem] {
        let axApp = AXUIElementCreateApplication(runApp.processIdentifier)
        // Default AX messaging timeout is ~6 seconds; an unresponsive app can stall
        // the whole enumeration. Cap each app's RPC at 500ms.
        AXUIElementSetMessagingTimeout(axApp, 0.5)
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

        // Keep only real, movable icons: drop zero-width phantom elements
        // (Control Center exposes several) and items the user cannot
        // reposition (the Control Center icon and the clock).
        let movable = elementsArray.filter { element in
            guard let frame = elementFrame(element), frame.width > 0 else { return false }
            let identifier = stringAttribute(element, kAXIdentifierAttribute)
            let bundleID = owningApp(of: element)?.bundleIdentifier
            return !Self.isExcludedSystemItem(bundleID: bundleID, axIdentifier: identifier)
        }
        return movable.enumerated().map { index, element in
            makeItem(from: element, siblingCount: movable.count, index: index)
        }
    }

    private func makeItem(
        from element: AXUIElement,
        siblingCount: Int,
        index: Int
    ) -> MenubarItem {
        let owner = owningApp(of: element)
        let bundleID = owner?.bundleIdentifier
        let axIdentifier = stringAttribute(element, kAXIdentifierAttribute)
        let displayName = bestDisplayName(
            element: element,
            owner: owner,
            bundleID: bundleID,
            axIdentifier: axIdentifier
        )
        let frame = elementFrame(element) ?? .zero
        let id = MenubarItemID.make(
            bundleID: bundleID,
            displayName: displayName,
            axIdentifier: axIdentifier,
            siblingCount: siblingCount,
            index: index
        )
        // Treat every enumerated item as controllable in the UI. Whether macOS
        // actually allows cmd-drag to move a given item past the sleev separator
        // is validated at drag time by the M4 DragSimulator; failures surface as
        // error banners rather than upfront greying-out.
        return MenubarItem(
            id: id,
            bundleID: bundleID,
            displayName: displayName,
            icon: systemExtraIcon(forAXIdentifier: axIdentifier) ?? lookupIcon(forBundleID: bundleID),
            frame: frame,
            zone: .visible,
            isControllable: true
        )
    }

    private func bestDisplayName(
        element: AXUIElement,
        owner: NSRunningApplication?,
        bundleID: String?,
        axIdentifier: String?
    ) -> String {
        // 1. Use AX title if non-empty.
        if let axTitle = stringAttribute(element, kAXTitleAttribute), !axTitle.isEmpty {
            return axTitle
        }
        // 2. System menu extras carry no title; derive a readable name from
        //    their Accessibility identifier.
        if let axIdentifier, let name = Self.systemExtraName(fromAXIdentifier: axIdentifier) {
            return name
        }
        // 3. Fall back to the owning app's localized name.
        if let localized = owner?.localizedName, !localized.isEmpty {
            return localized
        }
        // 4. Last resort: last segment of the bundle ID.
        if let bundleID, let last = bundleID.split(separator: ".").last {
            return String(last).capitalized
        }
        return "(untitled)"
    }

    /// Derives a readable name for a system menu extra (Wi-Fi, Bluetooth, ...)
    /// from its `com.apple.menuextra.*` Accessibility identifier. Returns nil
    /// for any other identifier, so third-party items are unaffected.
    private static func systemExtraName(fromAXIdentifier identifier: String) -> String? {
        let prefix = "com.apple.menuextra."
        guard identifier.hasPrefix(prefix) else { return nil }
        let slug = String(identifier.dropFirst(prefix.count))
        if slug == "wifi" { return "Wi-Fi" }
        return slug
            .split(separator: "-")
            .map(\.capitalized)
            .joined(separator: " ")
    }

    /// Returns an SF Symbol image for a known system menu extra (Wi-Fi,
    /// Sound, Battery, Now Playing), so the popover shows a recognizable glyph
    /// instead of the generic Control Center icon. Returns nil for anything
    /// else — Bluetooth has no SF Symbol and falls back to the generic icon.
    private func systemExtraIcon(forAXIdentifier axIdentifier: String?) -> NSImage? {
        guard let axIdentifier else { return nil }
        let symbolName: String
        switch axIdentifier {
        case "com.apple.menuextra.wifi": symbolName = "wifi"
        case "com.apple.menuextra.sound": symbolName = "speaker.wave.2.fill"
        case "com.apple.menuextra.battery": symbolName = "battery.100percent"
        case "com.apple.menuextra.now-playing": symbolName = "play.fill"
        default: return nil
        }
        guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else { return nil }
        let icon = symbol.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        ) ?? symbol
        icon.isTemplate = true
        return icon
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
