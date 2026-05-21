import AppKit
import SwiftUI

/// The popover root: menubar icons split into an "In menu bar" section and a
/// "Sleeved" section, each grid wrapped in a bento card with its title above.
/// Tapping a card sleeves / unsleeves it. Within each section items keep their
/// enumeration order, so toggling one does not reflow its neighbours. The
/// auto-hide toggle and overflow menu sit in a footer below the sections.
struct IconGridView: View {
    @ObservedObject var inventory: MenubarInventory
    @Binding var transientBanner: String?
    @Binding var persistentBanner: String?
    @State private var autoHideEnabled: Bool
    let onCardTap: (MenubarItem) -> Void
    let onToggleAutoHide: () -> Void
    let onAbout: () -> Void
    let onOpenRepository: () -> Void
    let onQuit: () -> Void
    let onDismissTransientBanner: () -> Void

    private let columns: [GridItem] = Array(repeating: .init(.fixed(50), spacing: 8), count: 4)
    @Namespace private var cardNamespace

    init(
        inventory: MenubarInventory,
        transientBanner: Binding<String?>,
        persistentBanner: Binding<String?>,
        isAutoHideEnabled: Bool,
        onCardTap: @escaping (MenubarItem) -> Void,
        onToggleAutoHide: @escaping () -> Void,
        onAbout: @escaping () -> Void,
        onOpenRepository: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        onDismissTransientBanner: @escaping () -> Void
    ) {
        _inventory = ObservedObject(wrappedValue: inventory)
        _transientBanner = transientBanner
        _persistentBanner = persistentBanner
        _autoHideEnabled = State(initialValue: isAutoHideEnabled)
        self.onCardTap = onCardTap
        self.onToggleAutoHide = onToggleAutoHide
        self.onAbout = onAbout
        self.onOpenRepository = onOpenRepository
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

            if inventory.items.isEmpty {
                if inventory.isLoading { loadingState } else { emptyState }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    section(title: "In menu bar", items: visibleItems)
                    section(
                        title: "Sleeved",
                        items: sleevedItems,
                        emptyHint: "Tap an icon to tuck it away."
                    )
                }
            }

            Divider()
            footer
        }
        .padding(14)
        .frame(width: 284)
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
        VStack(alignment: .leading, spacing: 6) {
            Text("\(title.uppercased()) · \(items.count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            sectionCard {
                if items.isEmpty, let emptyHint {
                    Text(emptyHint)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
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
    }

    /// Wraps a section's grid (or empty hint) in a rounded bento card so each
    /// zone reads as a distinct grouped panel on the popover material.
    private func sectionCard(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
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

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Toggle("Auto-hide", isOn: $autoHideEnabled)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize()
                .onChange(of: autoHideEnabled) { _, _ in
                    onToggleAutoHide()
                }
            Spacer()
            Button(action: onOpenRepository) {
                Image("github")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("View sleev on GitHub")
            Menu {
                Button("About sleev") { onAbout() }
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
