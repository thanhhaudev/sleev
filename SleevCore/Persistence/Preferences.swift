import Foundation

public struct Preferences {
    public enum Key {
        public static let autoHideEnabled = "sleev.preferences.autoHide.enabled"
        public static let autoHideDelay = "sleev.preferences.autoHide.delaySeconds"
        public static let toggleSleeveHotkey = "sleev.preferences.hotkey.toggleSleeve"
        public static let openPopoverHotkey = "sleev.preferences.hotkey.openPopover"
        public static let menuBarShowPill = "sleev.preferences.menuBar.showPill"
        public static let menuBarShowDots = "sleev.preferences.menuBar.showDots"
        public static let menuBarShowChevron = "sleev.preferences.menuBar.showChevron"
        public static let menuBarHandleSize = "sleev.preferences.menuBar.handleSize"
        public static let menuBarSeparatorSize = "sleev.preferences.menuBar.separatorSize"
        public static let menuBarSeparatorOpacity = "sleev.preferences.menuBar.separatorOpacity"
    }

    public static let defaultAutoHideDelay: TimeInterval = 10.0
    public static let defaultHandleSize: Double = 14
    public static let defaultSeparatorSize: Double = 6
    public static let defaultSeparatorOpacity: Double = 100

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = SleevDefaults.shared()) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.autoHideEnabled: false,
            Key.autoHideDelay: Self.defaultAutoHideDelay,
            Key.menuBarShowPill: true,
            Key.menuBarShowDots: true,
            Key.menuBarShowChevron: true,
            Key.menuBarHandleSize: Self.defaultHandleSize,
            Key.menuBarSeparatorSize: Self.defaultSeparatorSize,
            Key.menuBarSeparatorOpacity: Self.defaultSeparatorOpacity
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

    public var menuBarShowPill: Bool {
        get { defaults.bool(forKey: Key.menuBarShowPill) }
        set { defaults.set(newValue, forKey: Key.menuBarShowPill) }
    }

    public var menuBarShowDots: Bool {
        get { defaults.bool(forKey: Key.menuBarShowDots) }
        set { defaults.set(newValue, forKey: Key.menuBarShowDots) }
    }

    public var menuBarShowChevron: Bool {
        get { defaults.bool(forKey: Key.menuBarShowChevron) }
        set { defaults.set(newValue, forKey: Key.menuBarShowChevron) }
    }

    public var menuBarHandleSize: Double {
        get { defaults.double(forKey: Key.menuBarHandleSize) }
        set { defaults.set(newValue, forKey: Key.menuBarHandleSize) }
    }

    public var menuBarSeparatorSize: Double {
        get { defaults.double(forKey: Key.menuBarSeparatorSize) }
        set { defaults.set(newValue, forKey: Key.menuBarSeparatorSize) }
    }

    public var menuBarSeparatorOpacity: Double {
        get { defaults.double(forKey: Key.menuBarSeparatorOpacity) }
        set { defaults.set(newValue, forKey: Key.menuBarSeparatorOpacity) }
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
