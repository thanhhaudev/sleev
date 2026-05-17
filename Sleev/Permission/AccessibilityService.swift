import ApplicationServices
import Foundation
import SleevCore

/// Wraps the AX trust APIs from the main app's process. The main app holds the
/// Accessibility permission — see Bartender / Hidden Bar / AltTab for the same
/// pattern. The helper agent stays uninvolved in AX permission for Phase 1.
final class AccessibilityService {
    /// Current trust state (no prompt). Cheap; safe to poll.
    func currentState() -> AXPermissionState {
        AXIsProcessTrusted() ? .granted : .undetermined
    }

    /// Triggers the system permission prompt and opens System Settings →
    /// Privacy & Security → Accessibility. Returns post-prompt trust value
    /// (almost always false — the user hasn't toggled the switch yet).
    @discardableResult
    func promptForPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as CFString
        let options: CFDictionary = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
