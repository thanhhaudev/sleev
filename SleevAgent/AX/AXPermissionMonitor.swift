import Foundation
import SleevCore

final class AXPermissionMonitor {
    private let axService: AXService
    private var timer: DispatchSourceTimer?
    private var lastState: AXPermissionState = .undetermined
    private let queue = DispatchQueue(label: "dev.sleev.ax.monitor")

    var onChange: ((AXPermissionState) -> Void)?

    init(axService: AXService) {
        self.axService = axService
    }

    func start() {
        stop()
        let scheduledTimer = DispatchSource.makeTimerSource(queue: queue)
        scheduledTimer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        scheduledTimer.setEventHandler { [weak self] in
            guard let self else { return }
            let current = self.axService.currentState()
            if current != self.lastState {
                Log.accessibility.info("AX state changed: \(self.lastState.rawValue) -> \(current.rawValue)")
                self.lastState = current
                DispatchQueue.main.async { self.onChange?(current) }
            }
        }
        timer = scheduledTimer
        scheduledTimer.resume()
        lastState = axService.currentState()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }
}
