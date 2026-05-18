import AppKit
import SwiftUI

struct IconCardView: View {
    let item: MenubarItem
    let isInFlight: Bool
    let isOutOfSync: Bool
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
        if isOutOfSync {
            Circle().strokeBorder(Color.yellow, lineWidth: 1.5)
        } else if !isSleeved {
            Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon = item.icon {
            Image(nsImage: templateIcon(icon))
                .resizable()
                .interpolation(.high)
                .frame(width: 24, height: 24)
                .foregroundStyle(iconColor)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
        }
    }

    /// Force template rendering so colored app icons render as a monochrome
    /// silhouette that can be tinted to white (inactive) or the system
    /// Accent color (active).
    private func templateIcon(_ source: NSImage) -> NSImage {
        guard !source.isTemplate else { return source }
        let copy = source.copy() as? NSImage ?? source
        copy.isTemplate = true
        return copy
    }

    private var iconColor: Color {
        isSleeved ? systemAccent : Color.white
    }
}
