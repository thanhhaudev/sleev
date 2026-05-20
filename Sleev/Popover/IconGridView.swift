import AppKit
import SwiftUI

struct IconGridView: View {
    @ObservedObject var inventory: MenubarInventory
    @Binding var inFlightIDs: Set<MenubarItem.ID>
    let isAutoHideEnabled: Bool
    let onCardTap: (MenubarItem) -> Void
    let onToggleAutoHide: () -> Void
    let onQuit: () -> Void
    /// M4-1 throwaway: triggers a validation drag. Removed in M4-3.
    let onDebugDrag: () -> Void

    private let columns: [GridItem] = Array(repeating: .init(.fixed(64), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            chipsRow
            Divider()

            if inventory.items.isEmpty {
                if inventory.isLoading {
                    loadingState
                } else {
                    emptyState
                }
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(inventory.items) { item in
                        IconCardView(
                            item: item,
                            isInFlight: inFlightIDs.contains(item.id),
                            isOutOfSync: inventory.outOfSyncItems.contains { $0.id == item.id },
                            onTap: { onCardTap(item) }
                        )
                    }
                }
            }

            Divider()
            footer
        }
        .padding(14)
        .frame(width: 320)
    }

    // MARK: - Header chips

    private var chipsRow: some View {
        HStack(spacing: 8) {
            Chip(label: "sleeved", value: sleevedCount)
            Chip(label: "pinned", value: pinnedCount)
            Spacer()
        }
    }

    private var sleevedCount: Int {
        inventory.controllableItems.filter { $0.zone == .sleeved }.count
    }

    private var pinnedCount: Int {
        inventory.controllableItems.filter { $0.zone == .visible }.count
    }

    private var loadingState: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Loading menubar items\u{2026}")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No menubar items detected")
                .font(.system(size: 12, weight: .medium))
            Text("Grant Accessibility and ensure menubar apps are running.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var footer: some View {
        HStack {
            Button(action: onToggleAutoHide) {
                Text(isAutoHideEnabled ? "Disable Auto Collapse" : "Enable Auto Collapse")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: onDebugDrag) {
                Text("Debug drag")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: onQuit) {
                Text("Quit sleev")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct Chip: View {
    let label: String
    let value: Int

    private var systemAccent: Color {
        Color(nsColor: .controlAccentColor)
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(systemAccent)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
