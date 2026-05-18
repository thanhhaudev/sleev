import AppKit
import ServiceManagement
import SleevCore

@main
final class SleevApp: NSObject, NSApplicationDelegate, OnboardingViewControllerDelegate {
    private enum RunMode {
        case onboardingPreview
        case statusBarPreview
        case real
    }

    private let onboardingWindow = OnboardingWindowController()
    private let onboardingVC = OnboardingViewController()
    private let accessibility = AccessibilityService()
    private var statusBar: StatusBarController?
    private var runMode: RunMode = .real
    private var pollTimer: Timer?

    static func main() {
        let app = NSApplication.shared
        let delegate = SleevApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_: Notification) {
        Log.app.info("Sleev launched (args=\(CommandLine.arguments.joined(separator: " "), privacy: .public))")

        // v0.1 → v0.2 migration: make launchd forget the helper service that no
        // longer exists. Safe to call when no registration exists; the throw is
        // ignored intentionally.
        try? SMAppService.agent(plistName: "SleevAgent.plist").unregister()

        if CommandLine.arguments.contains("--preview-onboarding") {
            runMode = .onboardingPreview
            runOnboardingPreview()
            return
        }
        if CommandLine.arguments.contains("--preview-statusbar") {
            runMode = .statusBarPreview
            runStatusBarPreview()
            return
        }

        runMode = .real
        onboardingVC.delegate = self
        onboardingWindow.install(viewController: onboardingVC)
        apply(state: accessibility.currentState())
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        Log.app.info("Reopen requested (hasVisibleWindows=\(hasVisibleWindows))")
        if runMode == .real {
            apply(state: accessibility.currentState())
        }
        return true
    }

    private func apply(state: AXPermissionState) {
        switch state {
        case .granted:
            stopPolling()
            onboardingWindow.dismiss()
            if statusBar == nil {
                statusBar = StatusBarController()
                Log.app.info("Status bar installed")
            }
        case .undetermined, .denied:
            statusBar = nil
            Log.app.info("Status bar removed")
            onboardingWindow.present()
            startPolling()
        }
    }

    private func startPolling() {
        guard pollTimer == nil else { return }
        Log.app.info("Polling AX state every 1.5s while onboarding shown")
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.accessibility.currentState() == .granted {
                self.apply(state: .granted)
            }
        }
    }

    private func stopPolling() {
        guard pollTimer != nil else { return }
        Log.app.info("Stopping AX poll")
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Previews

    private func runOnboardingPreview() {
        onboardingVC.delegate = self
        onboardingWindow.install(viewController: onboardingVC)
        onboardingWindow.present()
    }

    private func runStatusBarPreview() {
        statusBar = StatusBarController()
        Log.app.info("Status bar preview installed")
    }

    // MARK: - OnboardingViewControllerDelegate

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
        }
    }

    func onboardingViewControllerDidRequestCheckNow(_: OnboardingViewController) {
        if runMode == .real {
            apply(state: accessibility.currentState())
        }
    }

    func onboardingViewControllerDidRequestQuit(_: OnboardingViewController) {
        Log.app.info("Quit tapped")
        NSApp.terminate(nil)
    }
}
