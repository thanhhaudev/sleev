import AppKit
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
        RunLoop.main.run()
        _ = monitor
    }
}
