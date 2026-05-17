import AppKit
import SleevCore

@main
struct AgentMain {
    static func main() {
        NSLog("SleevAgent launched, SleevCore.version = %@", SleevCore.version)
        RunLoop.main.run()
    }
}
