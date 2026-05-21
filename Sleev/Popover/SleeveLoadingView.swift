import SwiftUI

/// Animated loading indicator built from sleev's •••◀ glyph: the chevron flips
/// in, the three dots appear right-to-left, then the dots bounce in a loop —
/// with a random deadpan one-liner below.
struct SleeveLoadingView: View {
    /// Loading lines, picked at random — deadpan, matching the About tagline.
    private static let messages = [
        "Rounding up the menu bar icons.",
        "Counting icons nobody remembers installing.",
        "Doing a headcount up top.",
        "Finding the icons that actually earn their spot.",
        "Tidying the menu bar. It had it coming.",
        "Looking for icons hiding behind other icons.",
        "Negotiating with the menu bar.",
        "Checking the menu bar. Still crowded up there."
    ]

    private static func randomMessage() -> String {
        messages[Int.random(in: 0 ..< messages.count)]
    }

    // Geometry — SleeveGlyph proportions, scaled down for the loading state.
    private let dotDiameter: CGFloat = 5.5
    private let glyphSpacing: CGFloat = 4.5
    private let triangleSize = CGSize(width: 11, height: 14.5)
    private let bounceHeight: CGFloat = 4

    private let flipDuration: TimeInterval = 0.35
    private let dotRevealDuration: TimeInterval = 0.22
    private let dotStagger: TimeInterval = 0.12

    @State private var chevronFlipped = false
    @State private var dotsRevealed = 0
    @State private var isBouncing = false
    @State private var message = SleeveLoadingView.randomMessage()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            glyph
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading menu bar items")
        .task { await runIntro() }
    }

    private var glyph: some View {
        HStack(spacing: glyphSpacing) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(.white)
                    .frame(width: dotDiameter, height: dotDiameter)
                    .scaleEffect(isDotRevealed(index) ? 1 : 0.4)
                    .opacity(isDotRevealed(index) ? 1 : 0)
                    .offset(y: isBouncing ? -bounceHeight : 0)
                    .animation(bounceAnimation(index: index), value: isBouncing)
            }
            Chevron()
                .fill(.white)
                .frame(width: triangleSize.width, height: triangleSize.height)
                .rotation3DEffect(
                    .degrees(chevronFlipped ? 0 : 90),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(chevronFlipped ? 1 : 0)
        }
    }

    /// Dots are revealed right-to-left: the rightmost dot (index 2) first.
    private func isDotRevealed(_ index: Int) -> Bool {
        dotsRevealed >= 3 - index
    }

    /// Looping bounce; the per-dot delay (rightmost first) makes a wave.
    private func bounceAnimation(index: Int) -> Animation {
        .easeInOut(duration: 0.4)
            .repeatForever(autoreverses: true)
            .delay(Double(2 - index) * dotStagger)
    }

    /// Plays the one-time assembly, then starts the looping bounce. With
    /// Reduce Motion on, jumps straight to the static assembled glyph.
    private func runIntro() async {
        if reduceMotion {
            chevronFlipped = true
            dotsRevealed = 3
            return
        }
        withAnimation(.easeOut(duration: flipDuration)) {
            chevronFlipped = true
        }
        try? await Task.sleep(for: .seconds(flipDuration))

        for _ in 0 ..< 3 {
            withAnimation(.easeOut(duration: dotRevealDuration)) {
                dotsRevealed += 1
            }
            try? await Task.sleep(for: .seconds(dotStagger))
        }

        isBouncing = true
    }
}

/// A left-pointing triangle — the chevron of the •••◀ glyph.
private struct Chevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    SleeveLoadingView()
        .padding(40)
        .background(.black)
}
