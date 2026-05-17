import AppKit
import SleevCore

@main
struct AgentMain {
    static func main() {
        Log.agent.info("SleevAgent launched")
        let xpc = XPCListener()
        xpc.start()
        RunLoop.main.run()
        _ = xpc
    }
}
