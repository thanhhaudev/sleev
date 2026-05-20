import AppKit

/// A neutral gray spinner shown as the mouse cursor while a synthetic drag
/// runs. macOS does not expose the system "wait" cursor (the rainbow
/// beachball) to apps — and the beachball would wrongly signal "app hung" —
/// so sleev draws its own neutral spinner to say "working" during the drag.
@MainActor
enum SpinnerCursor {
    private static let frameInterval: TimeInterval = 0.08
    private static var timer: Timer?
    private static var frameIndex = 0

    /// Twelve spinner frames, each the wheel rotated one spoke further.
    private static let frames: [NSCursor] = buildFrames()

    /// Switch the cursor to the animated spinner.
    static func start() {
        timer?.invalidate()
        frameIndex = 0
        frames[0].set()
        timer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { _ in
            MainActor.assumeIsolated {
                frameIndex = (frameIndex + 1) % frames.count
                frames[frameIndex].set()
            }
        }
    }

    /// Stop the spinner and return to the normal arrow cursor.
    static func stop() {
        timer?.invalidate()
        timer = nil
        NSCursor.arrow.set()
    }

    private static func buildFrames() -> [NSCursor] {
        let size: CGFloat = 20
        let count = 12
        return (0 ..< count).map { frame in
            let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
                guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                let center = CGPoint(x: size / 2, y: size / 2)
                ctx.setLineCap(.round)
                ctx.setLineWidth(2.2)
                for spoke in 0 ..< count {
                    let behind = (spoke - frame + count) % count
                    let alpha = 1.0 - Double(behind) / Double(count) * 0.82
                    let angle = CGFloat(spoke) / CGFloat(count) * 2 * .pi
                    let inner = CGPoint(
                        x: center.x + cos(angle) * 3.0,
                        y: center.y + sin(angle) * 3.0
                    )
                    let outer = CGPoint(
                        x: center.x + cos(angle) * 8.5,
                        y: center.y + sin(angle) * 8.5
                    )
                    ctx.setStrokeColor(NSColor(white: 0.32, alpha: alpha).cgColor)
                    ctx.move(to: inner)
                    ctx.addLine(to: outer)
                    ctx.strokePath()
                }
                return true
            }
            return NSCursor(image: image, hotSpot: NSPoint(x: size / 2, y: size / 2))
        }
    }
}
