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
    private var awaitingGrantRestart = false

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

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        Log.app.info("Reopen requested (hasVisibleWindows=\(hasVisibleWindows))")
        if runMode == .real {
            Task { await self.evaluatePermissionAndPresentUI() }
        }
        return true
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
            onboardingWindow.dismiss()
            if statusBar == nil {
                statusBar = StatusBarController()
                Log.app.info("Status bar installed")
            }
        case .undetermined, .denied:
            statusBar = nil
            Log.app.info("Status bar removed")
            onboardingWindow.present()
        }
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
            armRelaunchOnActivation()
        }
    }

    func onboardingViewControllerDidRequestQuit(_: OnboardingViewController) {
        Log.app.info("Quit tapped")
        NSApp.terminate(nil)
    }

    // MARK: - AgentClientObserver

    func agentClient(_: AgentClient, axStateDidChange state: AXPermissionState) {
        apply(state: state)
    }

    // MARK: - Self-relaunch after AX grant

    /// Arms a one-shot observer that fully relaunches the app the next time sleev
    /// becomes the active application. This is how Hidden Bar, AltTab, and similar
    /// menubar utilities defeat macOS's per-process AXIsProcessTrusted cache: the
    /// user grants in System Settings, returns to sleev, and a fresh process tree
    /// reads the new trust state on first start.
    private func armRelaunchOnActivation() {
        guard !awaitingGrantRestart else { return }
        awaitingGrantRestart = true
        Log.app.info("Self-relaunch armed; waiting for user to return to sleev")
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidActivateApplication(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func workspaceDidActivateApplication(_ notification: Notification) {
        guard awaitingGrantRestart else { return }
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        else { return }
        guard app.bundleIdentifier == Bundle.main.bundleIdentifier else { return }
        guard app.processIdentifier == ProcessInfo.processInfo.processIdentifier else { return }
        // It's us, and we were waiting.
        Log.app.info("sleev re-activated; relaunching for fresh AX state")
        awaitingGrantRestart = false
        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        relaunchSelf()
    }

    private func relaunchSelf() {
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 0.5 && open \"\(bundlePath)\""]
        do {
            try task.run()
        } catch {
            Log.app.fault("Self-relaunch shell failed: \(error.localizedDescription, privacy: .public)")
        }
        // Quit immediately; the detached shell will reopen us after 0.5s.
        NSApp.terminate(nil)
    }
}
