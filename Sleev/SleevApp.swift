import AppKit
import SleevCore

@main
final class SleevApp: NSObject, NSApplicationDelegate {
    private let agent = AgentClient()
    private let agentLifecycle = AgentLifecycle()

    static func main() {
        let app = NSApplication.shared
        let delegate = SleevApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_: Notification) {
        Log.app.info("Sleev launched")

        do {
            try agentLifecycle.register()
        } catch {
            Log.app.fault("AgentLifecycle.register failed: \(error.localizedDescription, privacy: .public)")
            // Continue — XPC ping will fail until the issue is resolved, but the app stays up
            // so the engineer can read OSLog and diagnose.
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
}
