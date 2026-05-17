import Foundation

public struct Preferences {
    public enum Key {
        public static let autoHideEnabled = "sleev.preferences.autoHide.enabled"
        public static let autoHideDelay = "sleev.preferences.autoHide.delaySeconds"
    }

    public static let defaultAutoHideDelay: TimeInterval = 10.0

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = AppGroupDefaults.shared()) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.autoHideEnabled: true,
            Key.autoHideDelay: Self.defaultAutoHideDelay
        ])
    }

    public var autoHideEnabled: Bool {
        get { defaults.bool(forKey: Key.autoHideEnabled) }
        set { defaults.set(newValue, forKey: Key.autoHideEnabled) }
    }

    public var autoHideDelaySeconds: TimeInterval {
        get { defaults.double(forKey: Key.autoHideDelay) }
        set { defaults.set(newValue, forKey: Key.autoHideDelay) }
    }
}
