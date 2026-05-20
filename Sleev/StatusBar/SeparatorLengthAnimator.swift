import AppKit
import QuartzCore

/// Smoothstep ease-in-out interpolation between two lengths.
enum LengthInterpolation {
    /// Interpolates `from`→`to` by `progress`. `progress` is clamped to
    /// `0...1` and shaped with smoothstep (`t*t*(3-2t)`) for an ease-in-out
    /// curve.
    static func interpolate(from: CGFloat, to target: CGFloat, progress: CGFloat) -> CGFloat {
        let clamped = max(0, min(1, progress))
        let eased = clamped * clamped * (3 - 2 * clamped)
        return from + (target - from) * eased
    }
}

/// Drives a single `CGFloat` (the separator's `NSStatusItem.length`)
/// smoothly from one value to another.
///
/// A `CADisplayLink` — added to the main run loop in `.common` mode, so it
/// keeps ticking even while the mouse is being tracked — interpolates the
/// value each frame. A `DispatchQueue.main.asyncAfter` backstop guarantees
/// the target is reached even if the display link never fires: the GCD main
/// queue is serviced in every run-loop mode.
final class SeparatorLengthAnimator {
    /// Called on every value change — each animated frame, and once with the
    /// exact target when the animation ends.
    var onValueChange: ((CGFloat) -> Void)?

    /// The most recently delivered value. The start point of the next
    /// `animate(to:duration:)`, so a mid-flight reversal continues smoothly.
    private(set) var currentValue: CGFloat

    private weak var displayLinkSource: NSView?
    private var displayLink: CADisplayLink?
    private var backstop: DispatchWorkItem?
    private var isAnimating = false

    private var fromValue: CGFloat = 0
    private var toValue: CGFloat = 0
    private var duration: TimeInterval = 0
    private var startTimestamp: CFTimeInterval = 0

    /// - Parameters:
    ///   - displayLinkSource: a view in a window — the display link is
    ///     created from it. The handle's status-item button is used.
    ///   - initialValue: the separator's current length at construction.
    init(displayLinkSource: NSView, initialValue: CGFloat) {
        self.displayLinkSource = displayLinkSource
        self.currentValue = initialValue
    }

    /// Animates `currentValue`→`target` over `duration`. A `duration` of `0`
    /// (or a missing display-link source) delivers the target immediately.
    /// Calling this mid-animation cancels the in-flight animation and starts
    /// a fresh one from the current value, reversing smoothly.
    func animate(to target: CGFloat, duration: TimeInterval) {
        stop()
        guard let source = displayLinkSource, duration > 0 else {
            deliver(target)
            return
        }
        fromValue = currentValue
        toValue = target
        self.duration = duration
        startTimestamp = 0
        isAnimating = true

        let link = source.displayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link

        let work = DispatchWorkItem { [weak self] in
            guard let self, self.isAnimating else { return }
            self.deliver(self.toValue)
            self.stop()
        }
        backstop = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05, execute: work)
    }

    // MARK: - Private

    @objc private func step(_ link: CADisplayLink) {
        if startTimestamp == 0 {
            startTimestamp = link.timestamp
        }
        let elapsed = link.timestamp - startTimestamp
        let progress = min(1, elapsed / duration)
        deliver(LengthInterpolation.interpolate(from: fromValue, to: toValue, progress: progress))
        if progress >= 1 {
            stop()
        }
    }

    private func deliver(_ value: CGFloat) {
        currentValue = value
        onValueChange?(value)
    }

    private func stop() {
        displayLink?.invalidate()
        displayLink = nil
        backstop?.cancel()
        backstop = nil
        isAnimating = false
    }
}
