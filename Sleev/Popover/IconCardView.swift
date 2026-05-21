import AppKit
import SwiftUI

struct IconCardView: View {
    let item: MenubarItem
    let isInFlight: Bool
    let onTap: () -> Void

    private static let circleDiameter: CGFloat = 52

    private var isSleeved: Bool {
        item.zone == .sleeved
    }

    /// System-wide Accent Color from System Settings → Appearance → Accent.
    /// Auto-updates when the user changes the system pref.
    private var systemAccent: Color {
        Color(nsColor: .controlAccentColor)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                circleBackground
                iconView

                if isInFlight {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 24, height: 24)
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(width: Self.circleDiameter, height: Self.circleDiameter)
            .opacity(item.isControllable ? 1.0 : 0.55)

            Text(item.displayName)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.75))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 64)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.isControllable, !isInFlight { onTap() }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(item.displayName)
        .accessibilityHint(item.isControllable ? (isSleeved ? "Unsleeve" : "Sleeve") : "Not controllable")
    }

    @ViewBuilder
    private var circleBackground: some View {
        if isSleeved {
            Circle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 1)
                .overlay(borderOverlay)
        } else {
            Circle()
                .glassEffect(.regular, in: .circle)
                .overlay(borderOverlay)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if !isSleeved {
            Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon = item.icon {
            // Render at natural fidelity. SwiftUI auto-tints when the NSImage
            // is flagged isTemplate (SF Symbols and true menubar glyphs);
            // colored Dock icons come through unchanged so apps remain
            // recognizable on the white active pill and glass inactive pill.
            // Aspect-fit keeps non-square symbols (battery, speaker) from
            // stretching.
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(iconColor)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
        }
    }

    /// Template glyphs (SF Symbols) carry no internal padding, so they render
    /// a little smaller than Dock icons to keep the grid visually even.
    private var iconSize: CGFloat {
        item.icon?.isTemplate == true ? 20 : 24
    }

    private var iconColor: Color {
        isSleeved ? systemAccent : Color.white
    }
}
