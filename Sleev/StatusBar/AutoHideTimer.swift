import Foundation
import SleevCore

final class AutoHideTimer {
    private var timer: Timer?
    private let preferences: Preferences

    var onFire: (() -> Void)?

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func scheduleIfEnabled() {
        cancel()
        guard preferences.autoHideEnabled else { return }
        let delay = preferences.autoHideDelaySeconds
        let scheduled = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Log.statusBar.info("AutoHideTimer fired after \(delay)s")
            self?.onFire?()
        }
        timer = scheduled
        Log.statusBar.info("AutoHideTimer scheduled in \(delay)s")
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
