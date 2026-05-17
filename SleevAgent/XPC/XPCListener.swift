import Foundation
import SleevCore

final class XPCListener: NSObject, NSXPCListenerDelegate {
    private let listener: NSXPCListener
    let service: AgentService

    init(axService: AXService) {
        self.listener = NSXPCListener(machServiceName: SleevXPC.machServiceName)
        self.service = AgentService(axService: axService)
        super.init()
        listener.delegate = self
    }

    func start() {
        listener.resume()
        Log.xpc.info("Agent XPC listener resumed on \(SleevXPC.machServiceName, privacy: .public)")
    }

    func listener(
        _: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: SleevAgentProtocol.self)
        newConnection.exportedObject = service

        newConnection.remoteObjectInterface = NSXPCInterface(with: SleevUIProtocol.self)
        if let proxy = newConnection.remoteObjectProxyWithErrorHandler({ error in
            Log.xpc.error("Agent: UI proxy error: \(error.localizedDescription, privacy: .public)")
        }) as? SleevUIProtocol {
            service.setUIProxy(proxy)
        }

        newConnection.invalidationHandler = { [weak self] in
            self?.service.setUIProxy(nil)
            Log.xpc.info("Agent: XPC connection invalidated")
        }
        newConnection.resume()
        Log.xpc.info("Agent: accepted new XPC connection")

        // Push the live AX state RIGHT NOW so the UI immediately knows whether to
        // show onboarding or install the menubar. Without this, a fresh agent that
        // booted up after the user already granted permission never tells anyone.
        service.pushCurrentAXState()
        return true
    }
}
