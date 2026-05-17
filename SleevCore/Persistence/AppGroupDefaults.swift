import Foundation

public enum AppGroupDefaults {
    public static func shared() -> UserDefaults {
        if let suite = UserDefaults(suiteName: SleevXPC.appGroupIdentifier) {
            return suite
        }
        Log.app.fault("App group UserDefaults unavailable; falling back to standard")
        return .standard
    }
}
