import Foundation
import ServiceManagement
import SleevCore

enum AgentLifecycleError: Error {
    case registrationFailed(Error)
    case unregistrationFailed(Error)
}

final class AgentLifecycle {
    private let service: SMAppService

    init() {
        self.service = SMAppService.agent(plistName: "SleevAgent.plist")
    }

    var status: SMAppService.Status { service.status }

    func register() throws {
        do {
            try service.register()
            Log.app.info("AgentLifecycle: registered, status=\(self.status.rawValue)")
        } catch {
            Log.app.error("AgentLifecycle: register failed: \(error.localizedDescription, privacy: .public)")
            throw AgentLifecycleError.registrationFailed(error)
        }
    }

    func unregister() throws {
        do {
            try service.unregister()
            Log.app.info("AgentLifecycle: unregistered")
        } catch {
            Log.app.error("AgentLifecycle: unregister failed: \(error.localizedDescription, privacy: .public)")
            throw AgentLifecycleError.unregistrationFailed(error)
        }
    }
}
