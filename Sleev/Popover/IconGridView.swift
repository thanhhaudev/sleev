import AppKit
import SwiftUI

/// The popover root: menubar icons split into an "In menu bar" section and a
/// "Sleeved" section, each grid wrapped in a bento card with its title above.
/// Tapping a card sleeves / unsleeves it. Within each section items keep their
/// enumeration order, so toggling one does not reflow its neighbours. An
/// overflow menu sits in a footer below the sections.
struct IconGridView: View {
    @ObservedObject var inventory: MenubarInventory
    @Binding var transientBanner: String?
    @Binding var persistentBanner: String?
    let onCardTap: (MenubarItem) -> Void
    let onAbout: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void
    let onDismissTransientBanner: () -> Void

    private let columns: [GridItem] = Array(repeating: .init(.fixed(50), spacing: 8), count: 4)
    @Namespace private var cardNamespace

    init(
        inventory: MenubarInventory,
        transientBanner: Binding<String?>,
        persistentBanner: Binding<String?>,
        onCardTap: @escaping (MenubarItem) -> Void,
        onAbout: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        onDismissTransientBanner: @escaping () -> Void
    ) {
        _inventory = ObservedObject(wrappedValue: inventory)
        _transientBanner = transientBanner
        _persistentBanner = persistentBanner
        self.onCardTap = onCardTap
        self.onAbout = onAbout
        self.onOpenSettings = onOpenSettings
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

            VStack(spacing: 6) {
                Divider()
                footer
            }
        }
        .padding(EdgeInsets(top: 14, leading: 14, bottom: 10, trailing: 14))
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
        SleeveLoadingView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
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
        HStack {
            Button { onQuit() } label: {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
            .help("Quit sleev")

            Spacer()

            Menu {
                Button("Settings\u{2026}") { onOpenSettings() }
                Button("About sleev") { onAbout() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("More options")
        }
    }
}
