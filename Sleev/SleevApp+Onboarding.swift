import AppKit
import SleevCore

// MARK: - OnboardingViewControllerDelegate

extension SleevApp {
    func onboardingViewControllerDidRequestOpenSettings(_: OnboardingViewController) {
        switch runMode {
        case .onboardingPreview, .statusBarPreview:
            Log.app.info("[stub] OpenSettings tapped")
            let alert = NSAlert()
            alert.messageText = "Stub: would open System Settings"
            alert.informativeText = "Real wiring lands in M2."
            alert.runModal()
        case .real:
            Log.app.info("OpenSettings: prompting from UI process")
            _ = accessibility.promptForPermission()
            // Flip the button to "I've granted, check now". AXIsProcessTrusted
            // caches its negative answer per-process on macOS, so the only
            // reliable recovery is to relaunch — see CheckNow below.
            onboardingVC.setMode(.checkNow)
        }
    }

    func onboardingViewControllerDidRequestCheckNow(_: OnboardingViewController) {
        guard runMode == .real else { return }
        Log.app.info("CheckNow: relaunching to pick up granted Accessibility")
        relaunchSelf()
    }

    func onboardingViewControllerDidRequestQuit(_: OnboardingViewController) {
        Log.app.info("Quit tapped")
        NSApp.terminate(nil)
    }

    private func relaunchSelf() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }
}
