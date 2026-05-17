import Foundation
import SleevCore

final class AgentService: NSObject, SleevAgentProtocol {
    func ping(reply: @escaping (String) -> Void) {
        Log.xpc.info("Agent: received ping")
        reply("pong")
    }
}
