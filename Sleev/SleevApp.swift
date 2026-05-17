import AppKit
import SleevCore

@main
final class SleevApp: NSObject, NSApplicationDelegate, OnboardingViewControllerDelegate {
    private let agent = AgentClient()
    private let agentLifecycle = AgentLifecycle()
    private let onboardingWindow = OnboardingWindowController()
    private let onboardingVC = OnboardingViewController()

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
            runOnboardingPreview()
            return
        }

        // Real flow (from M0.4). Preserved verbatim.
        do {
            try agentLifecycle.register()
        } catch {
            Log.app.fault("AgentLifecycle.register failed: \(error.localizedDescription, privacy: .public)")
        }

        agent.connect()
        Task {
            do {
                let response = try await agent.ping()
                Log.app.info("UI: agent ping reply = \(response, privacy: .public)")
            } catch {
                Log.app.error("UI: agent ping failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Onboarding preview

    private func runOnboardingPreview() {
        onboardingVC.delegate = self
        onboardingWindow.install(viewController: onboardingVC)
        onboardingWindow.present()
    }

    // MARK: - OnboardingViewControllerDelegate (stub handlers)

    func onboardingViewControllerDidRequestOpenSettings(_: OnboardingViewController) {
        Log.app.info("[stub] OpenSettings tapped")
        let alert = NSAlert()
        alert.messageText = "Stub: would open System Settings"
        alert.informativeText = "Real wiring lands in M2."
        alert.runModal()
    }

    func onboardingViewControllerDidRequestQuit(_: OnboardingViewController) {
        Log.app.info("[stub] Quit tapped")
        NSApp.terminate(nil)
    }
}
