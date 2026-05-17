import Foundation
import SleevCore

final class AgentService: NSObject, SleevAgentProtocol {
    func ping(reply: @escaping (String) -> Void) {
        Log.xpc.info("Agent: received ping")
        reply("pong")
    }

    func requestAXStatus(reply: @escaping (Int) -> Void) {
        // M2 replaces this with a real AX check.
        reply(AXPermissionState.undetermined.rawValue)
    }

    func promptForAXPermission(reply: @escaping (Int) -> Void) {
        // M2 wires the real prompt.
        reply(AXPermissionState.undetermined.rawValue)
    }
}
