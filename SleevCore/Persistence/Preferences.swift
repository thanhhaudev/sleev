import Foundation

public struct Preferences {
    public enum Key {
        public static let autoHideEnabled = "sleev.preferences.autoHide.enabled"
        public static let autoHideDelay = "sleev.preferences.autoHide.delaySeconds"
        public static let toggleSleeveHotkey = "sleev.preferences.hotkey.toggleSleeve"
        public static let openPopoverHotkey = "sleev.preferences.hotkey.openPopover"
    }

    public static let defaultAutoHideDelay: TimeInterval = 10.0

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = AppGroupDefaults.shared()) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.autoHideEnabled: false,
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

    public var toggleSleeveHotkey: Hotkey? {
        get { hotkey(forKey: Key.toggleSleeveHotkey) }
        set { setHotkey(newValue, forKey: Key.toggleSleeveHotkey) }
    }

    public var openPopoverHotkey: Hotkey? {
        get { hotkey(forKey: Key.openPopoverHotkey) }
        set { setHotkey(newValue, forKey: Key.openPopoverHotkey) }
    }

    private func hotkey(forKey key: String) -> Hotkey? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Hotkey.self, from: data)
    }

    private func setHotkey(_ hotkey: Hotkey?, forKey key: String) {
        guard let hotkey, let data = try? JSONEncoder().encode(hotkey) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }
}
