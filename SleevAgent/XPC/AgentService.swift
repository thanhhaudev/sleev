import Foundation
import SleevCore

final class AgentService: NSObject, SleevAgentProtocol {
    private let axService: AXService
    private weak var uiProxy: SleevUIProtocol?

    init(axService: AXService) {
        self.axService = axService
        super.init()
    }

    func setUIProxy(_ proxy: SleevUIProtocol?) {
        uiProxy = proxy
    }

    func pushAXChange(_ state: AXPermissionState) {
        uiProxy?.axPermissionDidChange(rawValue: state.rawValue)
    }

    /// Reads the live state and pushes it. Called from XPCListener whenever a
    /// new connection is accepted so the UI doesn't have to know whether the
    /// agent just started, just restarted, or has been running for hours.
    func pushCurrentAXState() {
        let state = axService.currentState()
        Log.accessibility.info("Agent: pushing initial AX state = \(state.rawValue) for new connection")
        uiProxy?.axPermissionDidChange(rawValue: state.rawValue)
    }

    func ping(reply: @escaping (String) -> Void) {
        Log.xpc.info("Agent: received ping")
        reply("pong")
    }

    func requestAXStatus(reply: @escaping (Int) -> Void) {
        let state = axService.currentState()
        Log.accessibility.info("Agent: AX state = \(state.rawValue)")
        reply(state.rawValue)
    }

    func promptForAXPermission(reply: @escaping (Int) -> Void) {
        _ = axService.promptForPermission()
        reply(axService.currentState().rawValue)
    }

    func restartForFreshAXCheck(reply: @escaping (Int) -> Void) {
        Log.agent.info("Agent: restartForFreshAXCheck called; exiting so launchd respawns me")
        reply(0)
        // Defer exit so the XPC reply has time to be delivered. macOS's launchd
        // has a default 10s throttle on respawns (minimum runtime), so don't
        // bother retrying faster than that on our side.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            exit(0)
        }
    }
}
