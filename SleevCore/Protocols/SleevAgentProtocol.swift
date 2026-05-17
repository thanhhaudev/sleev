import Foundation

public enum SleevXPC {
    public static let machServiceName = "com.thanhhaudev.sleev.Sleev.Agent.xpc"
    public static let appGroupIdentifier = "group.com.thanhhaudev.sleev"
}

@objc public protocol SleevAgentProtocol {
    func ping(reply: @escaping (String) -> Void)
}

public enum AXPermissionState: Int, Codable, Sendable {
    case undetermined = 0
    case denied = 1
    case granted = 2
}
