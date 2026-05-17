import AppKit
import SleevCore

@main
struct AgentMain {
    static func main() {
        Log.agent.info("SleevAgent launched")
        RunLoop.main.run()
    }
}
