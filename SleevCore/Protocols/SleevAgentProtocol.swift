import Foundation

public enum SleevXPC {
    public static let machServiceName = "dev.sleev.Sleev.Agent.xpc"
    public static let appGroupIdentifier = "group.dev.sleev"
}

@objc public protocol SleevAgentProtocol {
    func ping(reply: @escaping (String) -> Void)
    func requestAXStatus(reply: @escaping (Int) -> Void)
    func promptForAXPermission(reply: @escaping (Int) -> Void)
    /// Triggers the agent to exit so launchd respawns it. Used by the UI to bypass
    /// AXIsProcessTrusted's per-process cache while waiting for the user to grant
    /// Accessibility in System Settings. The reply fires before exit so the caller
    /// doesn't see an XPC error.
    func restartForFreshAXCheck(reply: @escaping (Int) -> Void)
}

@objc public protocol SleevUIProtocol {
    func axPermissionDidChange(rawValue: Int)
}

public enum AXPermissionState: Int, Codable, Sendable {
    case undetermined = 0
    case denied = 1
    case granted = 2
}
