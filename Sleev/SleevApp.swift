import AppKit
import SleevCore

@main
final class SleevApp: NSObject, NSApplicationDelegate, OnboardingViewControllerDelegate, AgentClientObserver {
    private enum RunMode {
        case onboardingPreview
        case statusBarPreview
        case real
    }

    private let agent = AgentClient()
    private let agentLifecycle = AgentLifecycle()
    private let onboardingWindow = OnboardingWindowController()
    private let onboardingVC = OnboardingViewController()
    private var statusBar: StatusBarController?
    private var runMode: RunMode = .real
    private var grantPollingTask: Task<Void, Never>?

    static func main() {
        let app = NSApplication.shared
        let delegate = SleevApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_: Notification) {
        Log.app.info("Sleev launched (args=\(CommandLine.arguments.joined(separator: " "), privacy: .public))")

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
        agent.observer = self

        do {
            try agentLifecycle.register()
        } catch {
            Log.app.fault("AgentLifecycle.register failed: \(error.localizedDescription, privacy: .public)")
        }

        agent.connect()
        Task { await self.evaluatePermissionAndPresentUI() }
    }

    private func evaluatePermissionAndPresentUI() async {
        do {
            let state = try await agent.requestAXStatus()
            await MainActor.run { self.apply(state: state) }
        } catch {
            Log.app.error("UI: initial AX query failed: \(error.localizedDescription, privacy: .public)")
            await MainActor.run { self.onboardingWindow.present() }
        }
    }

    private func apply(state: AXPermissionState) {
        switch state {
        case .granted:
            stopGrantPolling()
            onboardingWindow.dismiss()
            if statusBar == nil {
                statusBar = StatusBarController()
                Log.app.info("Status bar installed")
            }
        case .undetermined, .denied:
            statusBar = nil
            Log.app.info("Status bar removed")
            onboardingWindow.present()
            startGrantPolling()
        }
    }

    private func startGrantPolling() {
        if grantPollingTask != nil { return }
        Log.app.info("Grant polling: starting")
        let agent = self.agent
        grantPollingTask = Task {
            // Small initial delay so we don't kill the agent before the user has
            // even reached System Settings.
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            while !Task.isCancelled {
                Log.app.info("Grant polling: tick — asking agent to respawn")
                try? await agent.restartForFreshAXCheck()
                // launchd's default throttle is ~10s between restarts; pace ourselves.
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    private func stopGrantPolling() {
        guard grantPollingTask != nil else { return }
        Log.app.info("Grant polling: stopping")
        grantPollingTask?.cancel()
        grantPollingTask = nil
    }

    // MARK: - Previews

    private func runOnboardingPreview() {
        onboardingVC.delegate = self
        onboardingWindow.install(viewController: onboardingVC)
        onboardingWindow.present()
    }

    private func runStatusBarPreview() {
        statusBar = StatusBarController()
        Log.app.info("Status bar preview installed; right-click the chevron for the menu.")
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
            Task { _ = try? await self.agent.promptForAXPermission() }
        }
    }

    func onboardingViewControllerDidRequestQuit(_: OnboardingViewController) {
        Log.app.info("Quit tapped")
        NSApp.terminate(nil)
    }

    // MARK: - NSApplicationDelegate extras

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        Log.app.info("Reopen requested (hasVisibleWindows=\(hasVisibleWindows))")
        if runMode == .real {
            Task { await self.evaluatePermissionAndPresentUI() }
        }
        return true
    }

    // MARK: - AgentClientObserver

    func agentClient(_: AgentClient, axStateDidChange state: AXPermissionState) {
        apply(state: state)
    }
}
