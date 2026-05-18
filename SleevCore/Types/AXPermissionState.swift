import Foundation

public enum AXPermissionState: Int, Codable, Sendable {
    case undetermined = 0
    case denied = 1
    case granted = 2
}
