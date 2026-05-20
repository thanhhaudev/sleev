@testable import SleevCore
import XCTest

final class PreferencesTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "com.thanhhaudev.sleev.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func test_defaultValues() {
        let prefs = Preferences(defaults: defaults)
        XCTAssertFalse(prefs.autoHideEnabled)
        XCTAssertEqual(prefs.autoHideDelaySeconds, 10.0)
    }

    func test_setAndPersistAutoHideDelay() {
        var prefs = Preferences(defaults: defaults)
        prefs.autoHideDelaySeconds = 3.5
        XCTAssertEqual(Preferences(defaults: defaults).autoHideDelaySeconds, 3.5)
    }

    func test_autoHideEnabledToggle() {
        var prefs = Preferences(defaults: defaults)
        prefs.autoHideEnabled = false
        XCTAssertFalse(Preferences(defaults: defaults).autoHideEnabled)
    }
}
