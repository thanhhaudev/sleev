import Foundation
import SleevCore

enum AgentClientError: Error {
    case remoteObjectUnavailable
}

final class AgentClient {
    private var connection: NSXPCConnection?

    func connect() {
        let conn = NSXPCConnection(machServiceName: SleevXPC.machServiceName, options: [])
        conn.remoteObjectInterface = NSXPCInterface(with: SleevAgentProtocol.self)
        conn.invalidationHandler = { Log.xpc.info("UI: XPC connection invalidated") }
        conn.interruptionHandler = { Log.xpc.info("UI: XPC connection interrupted") }
        conn.resume()
        connection = conn
        Log.xpc.info("UI: XPC client connected")
    }

    func ping() async throws -> String {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            guard let proxy = connection?.remoteObjectProxyWithErrorHandler({ error in
                Log.xpc.error("UI: proxy error: \(error.localizedDescription, privacy: .public)")
                cont.resume(throwing: AgentClientError.remoteObjectUnavailable)
            }) as? SleevAgentProtocol else {
                cont.resume(throwing: AgentClientError.remoteObjectUnavailable)
                return
            }
            proxy.ping { reply in cont.resume(returning: reply) }
        }
    }
}
