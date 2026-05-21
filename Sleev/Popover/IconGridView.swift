import AppKit
import SwiftUI

/// The popover root: menubar icons split into an "In menu bar" section and a
/// "Sleeved" section. Tapping a card sleeves / unsleeves it. Within each
/// section items keep their enumeration order, so toggling one does not
/// reflow its neighbours.
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
    @Namespace private var cardNamespace

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
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        section(title: "In menu bar", items: visibleItems)
                        section(
                            title: "Sleeved",
                            items: sleevedItems,
                            emptyHint: "Tap an icon to tuck it away."
                        )
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: 460)
            }
        }
        .padding(14)
        .frame(width: 320)
    }

    // MARK: - Sections

    private var visibleItems: [MenubarItem] {
        inventory.items.filter { $0.zone == .visible }
    }

    private var sleevedItems: [MenubarItem] {
        inventory.items.filter { $0.zone == .sleeved }
    }

    private func section(
        title: String,
        items: [MenubarItem],
        emptyHint: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title.uppercased()) · \(items.count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            if items.isEmpty, let emptyHint {
                Text(emptyHint)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        IconCardView(
                            item: item,
                            isInFlight: inventory.inFlightIDs.contains(item.id),
                            namespace: cardNamespace,
                            onTap: { onCardTap(item) }
                        )
                    }
                }
            }
        }
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

    // MARK: - Header

    private var header: some View {
        HStack {
            Toggle("Auto-hide", isOn: $autoHideEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize()
                .onChange(of: autoHideEnabled) { _, _ in
                    onToggleAutoHide()
                }
            Spacer()
            Menu {
                Button("About sleev") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
                Divider()
                Button("Quit sleev") { onQuit() }
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("More options")
        }
    }
}
