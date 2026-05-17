import Foundation
import SleevCore

enum AgentClientError: Error {
    case remoteObjectUnavailable
}

protocol AgentClientObserver: AnyObject {
    func agentClient(_ client: AgentClient, axStateDidChange state: AXPermissionState)
    func agentClientDidReconnect(_ client: AgentClient)
}

final class AgentClient: NSObject, SleevUIProtocol {
    private var connection: NSXPCConnection?
    weak var observer: AgentClientObserver?

    func connect() {
        let conn = NSXPCConnection(machServiceName: SleevXPC.machServiceName, options: [])
        conn.remoteObjectInterface = NSXPCInterface(with: SleevAgentProtocol.self)
        conn.exportedInterface = NSXPCInterface(with: SleevUIProtocol.self)
        conn.exportedObject = self
        conn.invalidationHandler = { [weak self] in
            Log.xpc.info("UI: XPC connection invalidated; scheduling reconnect")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.reconnect()
            }
        }
        conn.interruptionHandler = {
            Log.xpc.info("UI: XPC connection interrupted")
        }
        conn.resume()
        connection = conn
        Log.xpc.info("UI: XPC client connected")
    }

    private func reconnect() {
        guard observer != nil else { return }
        connection = nil
        connect()
        observer?.agentClientDidReconnect(self)
    }

    func ping() async throws -> String {
        try await call { (proxy, cont: CheckedContinuation<String, Error>) in
            proxy.ping { reply in cont.resume(returning: reply) }
        }
    }

    func requestAXStatus() async throws -> AXPermissionState {
        let raw: Int = try await call { (proxy, cont: CheckedContinuation<Int, Error>) in
            proxy.requestAXStatus { reply in cont.resume(returning: reply) }
        }
        return AXPermissionState(rawValue: raw) ?? .undetermined
    }

    func promptForAXPermission() async throws -> AXPermissionState {
        let raw: Int = try await call { (proxy, cont: CheckedContinuation<Int, Error>) in
            proxy.promptForAXPermission { reply in cont.resume(returning: reply) }
        }
        return AXPermissionState(rawValue: raw) ?? .undetermined
    }

    // MARK: - SleevUIProtocol

    func axPermissionDidChange(rawValue: Int) {
        let state = AXPermissionState(rawValue: rawValue) ?? .undetermined
        Log.app.info("UI: agent pushed AX state = \(state.rawValue)")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.observer?.agentClient(self, axStateDidChange: state)
        }
    }

    private func call<T>(
        _ body: @escaping (_ proxy: SleevAgentProtocol, _ cont: CheckedContinuation<T, Error>) -> Void
    ) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            guard let proxy = connection?.remoteObjectProxyWithErrorHandler({ error in
                Log.xpc.error("UI: proxy error: \(error.localizedDescription, privacy: .public)")
                cont.resume(throwing: AgentClientError.remoteObjectUnavailable)
            }) as? SleevAgentProtocol else {
                cont.resume(throwing: AgentClientError.remoteObjectUnavailable)
                return
            }
            body(proxy, cont)
        }
    }
}
