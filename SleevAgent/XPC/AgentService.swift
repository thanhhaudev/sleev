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
}
