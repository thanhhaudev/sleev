import CoreGraphics

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
