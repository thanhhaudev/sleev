/// Derives a stable, collision-free identifier for a single menu bar extra.
///
/// `MenubarEnumerator` previously keyed items by bundle identifier alone, so
/// every extra owned by one process — notably Control Center, which renders
/// Wi-Fi, Bluetooth, Battery, Sound, and Now Playing — collapsed into one id
/// and all but one were dropped by de-duplication.
enum MenubarItemID {
    /// - Parameters:
    ///   - bundleID: bundle identifier of the owning app, if any.
    ///   - displayName: the item's display name; used only when there is no
    ///     bundle identifier.
    ///   - axIdentifier: the element's `kAXIdentifierAttribute`, if any.
    ///   - siblingCount: how many extras the owning app contributes.
    ///   - index: this element's position among the owning app's extras.
    static func make(
        bundleID: String?,
        displayName: String,
        axIdentifier: String?,
        siblingCount: Int,
        index: Int
    ) -> String {
        let base = bundleID ?? "name:\(displayName)"
        guard siblingCount > 1 else { return base }
        if let axIdentifier, !axIdentifier.isEmpty {
            return "\(base)::\(axIdentifier)"
        }
        return "\(base)::idx\(index)"
    }
}
