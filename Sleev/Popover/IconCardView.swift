import AppKit
import SwiftUI

struct IconCardView: View {
    let item: MenubarItem
    let isInFlight: Bool
    let isOutOfSync: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: isOutOfSync ? 1.5 : 0.5)
                )

            VStack(spacing: 4) {
                if let icon = item.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
                Text(item.displayName)
                    .font(.system(size: 10))
                    .foregroundStyle(item.isControllable ? .primary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 6)
            .opacity(item.isControllable ? 1.0 : 0.55)

            if isInFlight {
                ProgressView()
                    .controlSize(.small)
                    .background(
                        Circle()
                            .fill(.thinMaterial)
                            .frame(width: 24, height: 24)
                    )
            }

            if item.zone == .sleeved, !isInFlight {
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                            .padding(.trailing, 6)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: 70, height: 80)
        .onTapGesture { if item.isControllable, !isInFlight { onTap() } }
    }

    private var backgroundColor: Color {
        switch item.zone {
        case .visible:
            Color(nsColor: .controlBackgroundColor)
        case .sleeved:
            Color.accentColor.opacity(0.15)
        }
    }

    private var borderColor: Color {
        if isOutOfSync {
            Color.yellow
        } else {
            Color(nsColor: .separatorColor)
        }
    }
}
