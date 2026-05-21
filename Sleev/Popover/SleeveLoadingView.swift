import SwiftUI

/// Animated loading indicator built from sleev's •••◀ glyph: the chevron flips
/// in, the three dots appear right-to-left, then the dots bounce in a loop.
struct SleeveLoadingView: View {
    // Geometry — SleeveGlyph unit ratios with u = 2.5pt.
    private let dotDiameter: CGFloat = 7.5
    private let glyphSpacing: CGFloat = 6.25
    private let triangleSize = CGSize(width: 15, height: 20)
    private let bounceHeight: CGFloat = 5

    private let flipDuration: TimeInterval = 0.35
    private let dotRevealDuration: TimeInterval = 0.22
    private let dotStagger: TimeInterval = 0.12

    @State private var chevronFlipped = false
    @State private var dotsRevealed = 0
    @State private var isBouncing = false

    var body: some View {
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading menu bar items")
        .task { await runIntro() }
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

    /// Plays the one-time assembly, then starts the looping bounce.
    private func runIntro() async {
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
