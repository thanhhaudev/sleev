import ApplicationServices
import Foundation
import SleevCore

final class AXService {
    /// Current trust state without prompting.
    ///
    /// `AXIsProcessTrusted` is binary; map `false` to `.undetermined` for the very first
    /// check. After the user has been shown the prompt, the polling monitor in
    /// AXPermissionMonitor sees the same `false` value but reports it as the unchanged
    /// "undetermined" state until the user toggles sleev on. We don't try to distinguish
    /// .denied from .undetermined at this layer — macOS doesn't expose that.
    func currentState() -> AXPermissionState {
        AXIsProcessTrusted() ? .granted : .undetermined
    }

    /// Triggers the system prompt and opens System Settings.
    @discardableResult
    func promptForPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as CFString
        let options: CFDictionary = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
