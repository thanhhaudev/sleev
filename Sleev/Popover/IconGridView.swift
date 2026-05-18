import AppKit
import SwiftUI

struct IconGridView: View {
    @ObservedObject var inventory: MenubarInventory
    @Binding var inFlightIDs: Set<MenubarItem.ID>
    let isAutoHideEnabled: Bool
    let onCardTap: (MenubarItem) -> Void
    let onToggleAutoHide: () -> Void
    let onQuit: () -> Void

    private let columns: [GridItem] = Array(repeating: .init(.fixed(70), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Menubar Icons")
                .font(.system(size: 13, weight: .semibold))

            if inventory.controllableItems.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(inventory.controllableItems) { item in
                        IconCardView(
                            item: item,
                            isInFlight: inFlightIDs.contains(item.id),
                            isOutOfSync: inventory.outOfSyncItems.contains { $0.id == item.id },
                            onTap: { onCardTap(item) }
                        )
                    }
                }
            }

            if !inventory.systemItems.isEmpty {
                Divider()
                Text("System icons (not editable)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(inventory.systemItems.map(\.displayName).joined(separator: " · "))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Divider()
            HStack {
                Button(action: onToggleAutoHide) {
                    Text(isAutoHideEnabled ? "Disable Auto Collapse" : "Enable Auto Collapse")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                Spacer()
                Button(action: onQuit) {
                    Text("Quit sleev")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No menubar apps detected")
                .font(.system(size: 12, weight: .medium))
            Text("Install a third-party menubar app to start.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
