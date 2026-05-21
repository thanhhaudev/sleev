import AppKit
import ServiceManagement
import SleevCore
import SwiftUI

@MainActor
@main
final class SleevApp: NSObject, NSApplicationDelegate, @preconcurrency OnboardingViewControllerDelegate {
    private enum RunMode {
        case onboardingPreview
        case statusBarPreview
        case real
    }

    private let onboardingWindow = OnboardingWindowController()
    private let onboardingVC = OnboardingViewController()
    private let accessibility = AccessibilityService()
    private let zoneStore = ZoneStore()
    private let enumerator = MenubarEnumerator()
    private let dragSimulator = DragSimulator()
    private var inventory: MenubarInventory!
    private var popover: PopoverPresenter!
    private var dragQueue: DragQueue!
    private var transientBanner: String?
    private var persistentBanner: String?
    private var statusBar: StatusBarController?
    private var runMode: RunMode = .real
    private var pollTimer: Timer?
    private var inventoryRefreshTimer: Timer?
    private var preferences = Preferences()

    static func main() {
        let app = NSApplication.shared
        let delegate = SleevApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_: Notification) {
        inventory = MenubarInventory(store: zoneStore)
        popover = PopoverPresenter()
        popover.onVisibilityChanged = { [weak self] open in self?.statusBar?.setPopoverOpen(open) }
        dragQueue = makeDragQueue()
        Log.app.info("Sleev launched (args=\(CommandLine.arguments.joined(separator: " "), privacy: .public))")
        try? SMAppService.agent(plistName: "SleevAgent.plist").unregister()

        if CommandLine.arguments.contains("--preview-onboarding") {
            runMode = .onboardingPreview
            runOnboardingPreview()
            return
        }
        if CommandLine.arguments.contains("--preview-statusbar") {
            runMode = .statusBarPreview
            runStatusBarPreview()
            return
        }

        runMode = .real
        onboardingVC.delegate = self
        onboardingWindow.install(viewController: onboardingVC)
        apply(state: accessibility.currentState())
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        Log.app.info("Reopen requested (hasVisibleWindows=\(hasVisibleWindows))")
        if runMode == .real {
            apply(state: accessibility.currentState())
        }
        return true
    }

    private func apply(state: AXPermissionState) {
        switch state {
        case .granted:
            stopPolling()
            onboardingWindow.dismiss()
            if statusBar == nil {
                let controller = StatusBarController()
                controller.onRightClick = { [weak self] in self?.openPopover() }
                statusBar = controller
                Log.app.info("Status bar installed")
            }
        case .undetermined, .denied:
            statusBar = nil
            popover.close()
            Log.app.info("Status bar removed")
            onboardingWindow.present()
            startPolling()
        }
    }

    // MARK: - Popover

    private func openPopover() {
        guard let button = statusBar?.handleButton else { return }
        refreshInventory()
        startInventoryRefresh()
        let root = IconGridView(
            inventory: inventory,
            transientBanner: Binding(
                get: { self.transientBanner },
                set: { self.transientBanner = $0 }
            ),
            persistentBanner: Binding(
                get: { self.persistentBanner },
                set: { self.persistentBanner = $0 }
            ),
            isAutoHideEnabled: preferences.autoHideEnabled,
            onCardTap: { [weak self] item in self?.handleCardTap(item: item) },
            onToggleAutoHide: { [weak self] in self?.toggleAutoHide() },
            onQuit: { NSApp.terminate(nil) },
            onDismissTransientBanner: { [weak self] in self?.transientBanner = nil }
        )
        popover.show(relativeTo: button, rootView: root)
    }

    private func makeDragQueue() -> DragQueue {
        DragQueue(
            simulator: dragSimulator,
            verifier: { [weak self] item, _ in
                // Re-enumerate after a short settle; the drag succeeded if the
                // item still exists and its x-position changed.
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard let self else { return false }
                let live = await MainActor.run { self.enumerator.enumerate() }
                return live.contains { $0.id == item.id && $0.frame.midX != item.frame.midX }
            }
        )
    }

    private func handleCardTap(item: MenubarItem) {
        guard item.isControllable else { return }
        inventory.setInFlight(item.id, true)
        let nextZone: Zone = item.zone == .visible ? .sleeved : .visible
        Task {
            // The bar must be expanded so every icon — including sleeved ones —
            // is on-screen and grabbable by the synthetic drag.
            if statusBar?.isCollapsed == true {
                statusBar?.expand()
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            // Re-read the icon's current on-screen frame; the cached one may be
            // stale (off-screen) from when the bar was collapsed.
            let fresh = await freshItem(id: item.id) ?? item
            let (source, target) = DragGeometry.endpoints(
                item: fresh,
                targetZone: nextZone,
                separatorFrame: statusBar?.separatorButton?.window?.frame,
                handleFrame: statusBar?.handleButton?.window?.frame
            )
            Log.drag.info("Drag: \(item.displayName, privacy: .public) src=\(source.x) tgt=\(target.x)")
            let result = await dragQueue.enqueue(item: fresh, source: source, target: target)
            self.inventory.setInFlight(item.id, false)
            if case .success = result {
                self.inventory.setZone(nextZone, forItemID: item.id)
            } else if case let .failure(error) = result {
                await self.handleDragFailure(item: item, error: error)
            }
            self.refreshInventory()
        }
    }

    private func freshItem(id: String) async -> MenubarItem? {
        let enumerator = self.enumerator
        let raw = await Task.detached(priority: .userInitiated) { enumerator.enumerate() }.value
        return raw.first { $0.id == id }
    }

    private func handleDragFailure(item: MenubarItem, error: DragError) async {
        Log.drag.error(
            "Drag failed for \(item.displayName, privacy: .public): \(String(describing: error), privacy: .public)"
        )
        let count = await dragQueue.consecutiveFailureCount
        if count >= 3 {
            persistentBanner = "Auto-drag isn't working on this Mac. Drag icons manually while holding ⌘."
        } else {
            transientBanner = "Couldn't move \(item.displayName). Try ⌘+drag manually."
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self.transientBanner = nil
            }
        }
    }

    private func toggleAutoHide() {
        preferences.autoHideEnabled.toggle()
        Log.app.info("autoHide.enabled toggled -> \(self.preferences.autoHideEnabled)")
    }

    private func refreshInventory() {
        let enumerator = self.enumerator
        Task { [weak self] in
            let raw = await Task.detached(priority: .userInitiated) {
                enumerator.enumerate()
            }.value
            guard let self else { return }
            self.inventory.apply(liveItems: raw)
            self.reconcileZones(items: raw)
            Log.app.info("inventory refreshed: \(raw.count) items")
        }
    }

    private func startInventoryRefresh() {
        guard inventoryRefreshTimer == nil else { return }
        inventoryRefreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                if self.popover.isShown {
                    self.refreshInventory()
                } else {
                    self.stopInventoryRefresh()
                }
            }
        }
    }

    private func stopInventoryRefresh() {
        inventoryRefreshTimer?.invalidate()
        inventoryRefreshTimer = nil
    }

    private func startPolling() {
        guard pollTimer == nil else { return }
        Log.app.info("Polling AX state every 1.5s while onboarding shown")
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                if self.accessibility.currentState() == .granted {
                    self.apply(state: .granted)
                }
            }
        }
    }

    private func stopPolling() {
        guard pollTimer != nil else { return }
        Log.app.info("Stopping AX poll")
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func runOnboardingPreview() {
        onboardingVC.delegate = self
        onboardingWindow.install(viewController: onboardingVC)
        onboardingWindow.present()
    }

    private func runStatusBarPreview() {
        let controller = StatusBarController()
        controller.onRightClick = { [weak self] in self?.openPopover() }
        statusBar = controller
        Log.app.info("Status bar preview installed; right-click handle to see popover")
    }

    func onboardingViewControllerDidRequestOpenSettings(_: OnboardingViewController) {
        switch runMode {
        case .onboardingPreview, .statusBarPreview:
            Log.app.info("[stub] OpenSettings tapped")
            let alert = NSAlert()
            alert.messageText = "Stub: would open System Settings"
            alert.informativeText = "Real wiring lands in M2."
            alert.runModal()
        case .real:
            Log.app.info("OpenSettings: prompting from UI process")
            _ = accessibility.promptForPermission()
        }
    }

    func onboardingViewControllerDidRequestCheckNow(_: OnboardingViewController) {
        if runMode == .real {
            apply(state: accessibility.currentState())
        }
    }

    func onboardingViewControllerDidRequestQuit(_: OnboardingViewController) {
        Log.app.info("Quit tapped")
        NSApp.terminate(nil)
    }
}

// MARK: - Zone reconciliation

extension SleevApp {
    /// Updates each on-screen icon's zone from its physical position relative
    /// to the separator, so the popover reflects manual ⌘-drag rearrangement.
    /// Runs only while the bar is expanded — collapsed positions are
    /// off-screen garbage. Icons on other displays keep their stored zone.
    private func reconcileZones(items: [MenubarItem]) {
        guard statusBar?.isCollapsed == false,
              let separatorWindow = statusBar?.separatorButton?.window,
              let screen = separatorWindow.screen,
              let primaryHeight = NSScreen.screens.first?.frame.height
        else { return }

        let separatorAX = ZoneReconciler.appKitRectToAX(
            separatorWindow.frame, primaryDisplayHeight: primaryHeight
        )
        let screenAX = ZoneReconciler.appKitRectToAX(
            screen.frame, primaryDisplayHeight: primaryHeight
        )
        let zones = ZoneReconciler.reconciledZones(
            items: items,
            separatorFrame: separatorAX,
            screenFrame: screenAX
        )
        for (id, zone) in zones where !inventory.inFlightIDs.contains(id) {
            inventory.setZone(zone, forItemID: id)
        }
    }
}
