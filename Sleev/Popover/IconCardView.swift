import AppKit
import SwiftUI

struct IconCardView: View {
    let item: MenubarItem
    let isInFlight: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    @State private var isHovering = false

    private static let circleDiameter: CGFloat = 52

    private var isSleeved: Bool {
        item.zone == .sleeved
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

            Text(item.displayName)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.75))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 64)
        .opacity(cardOpacity)
        .matchedGeometryEffect(id: item.id, in: namespace)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.isControllable, !isInFlight { onTap() }
        }
        .onHover { hovering in
            isHovering = hovering && item.isControllable && !isInFlight
        }
        .help(helpText)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(item.displayName)
        .accessibilityHint(item.isControllable ? (isSleeved ? "Unsleeve" : "Sleeve") : "Not controllable")
    }

    /// Sleeved items are dimmed so the popover reads "tucked away"; system
    /// items that can't be moved are dimmed further and never react to taps.
    private var cardOpacity: Double {
        if !item.isControllable { return 0.5 }
        return isSleeved ? 0.6 : 1.0
    }

    private var helpText: String {
        item.isControllable
            ? item.displayName
            : "\(item.displayName) — system item, can't be sleeved"
    }

    private var circleBackground: some View {
        Group {
            if isSleeved {
                Circle().fill(.quaternary)
            } else {
                Circle().glassEffect(.regular, in: .circle)
            }
        }
        .overlay(
            Circle().strokeBorder(
                Color.white.opacity(isHovering ? 0.35 : 0.15),
                lineWidth: isHovering ? 1 : 0.5
            )
        )
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon = item.icon {
            // foregroundStyle tints template glyphs (SF Symbols, true menubar
            // glyphs) white; colored Dock icons ignore it and render as-is.
            // saturation(0) desaturates those colored icons when sleeved so a
            // tucked-away app reads as muted. Aspect-fit keeps non-square
            // glyphs (battery, speaker) from stretching.
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(Color.white)
                .saturation(isSleeved ? 0 : 1)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 22))
                .foregroundStyle(Color.white)
        }
    }

    /// Template glyphs carry no internal padding, so they render a little
    /// smaller than Dock icons to keep the grid visually even.
    private var iconSize: CGFloat {
        item.icon?.isTemplate == true ? 20 : 24
    }
}
