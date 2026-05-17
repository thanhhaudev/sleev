import Foundation
import SleevCore

final class XPCListener: NSObject, NSXPCListenerDelegate {
    private let listener: NSXPCListener
    let service = AgentService()

    override init() {
        self.listener = NSXPCListener(machServiceName: SleevXPC.machServiceName)
        super.init()
        listener.delegate = self
    }

    func start() {
        listener.resume()
        Log.xpc.info("Agent XPC listener resumed on \(SleevXPC.machServiceName, privacy: .public)")
    }

    func listener(_: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: SleevAgentProtocol.self)
        newConnection.exportedObject = service
        newConnection.invalidationHandler = { Log.xpc.info("Agent: XPC connection invalidated") }
        newConnection.resume()
        Log.xpc.info("Agent: accepted new XPC connection")
        return true
    }
}
