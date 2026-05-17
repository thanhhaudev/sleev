import AppKit
import Foundation
import SleevCore

@main
struct AgentMain {
    static func main() {
        Log.agent.info("SleevAgent launched")

        let axService = AXService()
        let xpc = XPCListener(axService: axService)
        let monitor = AXPermissionMonitor(axService: axService)
        monitor.onChange = { [weak service = xpc.service] state in
            service?.pushAXChange(state)
        }
        xpc.start()
        monitor.start()

        // Restart agent when any AX permission changes, so AXIsProcessTrusted()
        // is queried by a fresh process. Without this, macOS's per-process AX
        // cache holds the initial false value forever.
        let observer = DistributedNotificationCenter.default.addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: nil
        ) { _ in
            Log.accessibility.info("AX permission change detected; agent exiting for fresh restart")
            exit(0)
        }
        _ = observer

        RunLoop.main.run()
        _ = monitor
    }
}
