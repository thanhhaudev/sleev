import AppKit
import SwiftUI

/// The popover root: a single grid of menubar icons. Tapping a card
/// sleeves / unsleeves it. Items keep a stable slot regardless of zone, so
/// toggling one does not reflow the others.
struct IconGridView: View {
    @ObservedObject var inventory: MenubarInventory
    @Binding var transientBanner: String?
    @Binding var persistentBanner: String?
    @State private var autoHideEnabled: Bool
    let onCardTap: (MenubarItem) -> Void
    let onToggleAutoHide: () -> Void
    let onQuit: () -> Void
    let onDismissTransientBanner: () -> Void

    private let columns: [GridItem] = Array(repeating: .init(.fixed(64), spacing: 8), count: 4)

    init(
        inventory: MenubarInventory,
        transientBanner: Binding<String?>,
        persistentBanner: Binding<String?>,
        isAutoHideEnabled: Bool,
        onCardTap: @escaping (MenubarItem) -> Void,
        onToggleAutoHide: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        onDismissTransientBanner: @escaping () -> Void
    ) {
        _inventory = ObservedObject(wrappedValue: inventory)
        _transientBanner = transientBanner
        _persistentBanner = persistentBanner
        _autoHideEnabled = State(initialValue: isAutoHideEnabled)
        self.onCardTap = onCardTap
        self.onToggleAutoHide = onToggleAutoHide
        self.onQuit = onQuit
        self.onDismissTransientBanner = onDismissTransientBanner
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let message = persistentBanner {
                ErrorBanner(severity: .persistentWarning, message: message, onDismiss: nil)
            }
            if let message = transientBanner {
                ErrorBanner(severity: .warning, message: message, onDismiss: onDismissTransientBanner)
            }

            header
            Divider()

            if inventory.items.isEmpty {
                if inventory.isLoading { loadingState } else { emptyState }
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(inventory.items) { item in
                        IconCardView(
                            item: item,
                            isInFlight: inventory.inFlightIDs.contains(item.id),
                            onTap: { onCardTap(item) }
                        )
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 320)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 8) {
            ProgressView().controlSize(.small)
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

    private var header: some View {
        HStack {
            Button {
                autoHideEnabled.toggle()
                onToggleAutoHide()
            } label: {
                HStack(spacing: 5) {
                    Circle()
                        .fill(autoHideEnabled ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text("Auto-hide")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: onQuit) {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quit sleev")
        }
    }
}
