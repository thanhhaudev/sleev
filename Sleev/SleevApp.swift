import AppKit
import ServiceManagement
import SleevCore
import SwiftUI

@MainActor
@main
final class SleevApp: NSObject, NSApplicationDelegate, @preconcurrency OnboardingViewControllerDelegate {
    enum RunMode {
        case onboardingPreview
        case statusBarPreview
        case real
    }

    private let onboardingWindow = OnboardingWindowController()
    let onboardingVC = OnboardingViewController()
    let accessibility = AccessibilityService()
    private let zoneStore = ZoneStore()
    private let enumerator = MenubarEnumerator()
    private let dragSimulator = DragSimulator()
    private var inventory: MenubarInventory!
    private var popover: PopoverPresenter!
    private var dragQueue: DragQueue!
    private var transientBanner: String?
    private var persistentBanner: String?
    private var statusBar: StatusBarController?
    private var preferencesWindow: PreferencesWindowController?
    private let hotkeyManager = HotkeyManager()
    var runMode: RunMode = .real
    private var pollTimer: Timer?
    private var inventoryRefreshTimer: Timer?

    static func main() {
        if NSClassFromString("XCTestCase") != nil {
            _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
            return
        }
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

        hotkeyManager.onPressed = { [weak self] action in
            switch action {
            case .toggleSleeve: self?.statusBar?.toggle()
            case .openPopover: self?.openPopover()
            }
        }
        applyHotkeys()

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

    func applicationDidBecomeActive(_: Notification) {
        // Belt-and-suspenders for the polling-timer .common-mode fix below.
        // Skip once the status bar is up — onboarding is already past us.
        guard runMode == .real, statusBar == nil else { return }
        apply(state: accessibility.currentState())
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
                // Pre-warm the inventory now so the first popover open shows the
                // grid immediately instead of waiting through a cold enumeration.
                refreshInventory()
            }
        case .undetermined, .denied:
            statusBar = nil
            popover.close()
            Log.app.info("Status bar removed")
            // Reset to the initial button label in case the user previously
            // clicked Open Settings (which flips it to "Check Now") and then
            // revoked the permission before granting.
            onboardingVC.setMode(.openSettings)
            onboardingWindow.present()
            startPolling()
        }
    }

    // MARK: - Popover

    private func openPopover() {
        guard let button = statusBar?.handleButton else { return }
        // Re-reconcile zones against the live separator position using
        // cached frames before showing. Catches user-moves of the separator
        // while the popover was closed, so the sleeved/visible split is
        // correct on first paint instead of flashing the old split until
        // the async refresh below catches up ~200ms later.
        reconcileZones(items: inventory.items)
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
            onCardTap: { [weak self] item in self?.handleCardTap(item: item) },
            onAbout: { [weak self] in self?.presentAbout() },
            onOpenSettings: { [weak self] in self?.openSettings() },
            onQuit: { NSApp.terminate(nil) },
            onDismissTransientBanner: { [weak self] in self?.transientBanner = nil }
        )
        popover.show(
            relativeTo: button,
            alsoDismissOnUserDragOf: [statusBar?.separatorButton?.window].compactMap { $0 },
            rootView: root
        )
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
                withAnimation(.snappy) {
                    self.inventory.setZone(nextZone, forItemID: item.id)
                }
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
        let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                if self.accessibility.currentState() == .granted {
                    self.apply(state: .granted)
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
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
}

// MARK: - Zone reconciliation

extension SleevApp {
    /// Updates each on-screen icon's zone from its horizontal position
    /// relative to the separator, so the popover reflects manual ⌘-drag
    /// rearrangement. Runs only while the bar is expanded — when collapsed the
    /// separator is ballooned and its position is meaningless. Icons on other
    /// displays fall outside the separator screen's x-range and keep their
    /// stored zone.
    private func reconcileZones(items: [MenubarItem]) {
        guard statusBar?.isCollapsed == false,
              let separatorWindow = statusBar?.separatorButton?.window,
              let screen = separatorWindow.screen ?? NSScreen.main
        else { return }

        let separatorMidX = separatorWindow.frame.midX
        let zones = ZoneReconciler.reconciledZones(
            items: items,
            separatorMidX: separatorMidX,
            screenXRange: screen.frame.minX ... screen.frame.maxX
        )
        for (id, zone) in zones where !inventory.inFlightIDs.contains(id) {
            inventory.setZone(zone, forItemID: id)
        }
        Log.app.info(
            "reconcileZones: separatorMidX=\(separatorMidX), \(zones.count) items on the separator's screen"
        )
    }
}

// MARK: - Popover actions

extension SleevApp {
    private func presentAbout() {
        popover.close()
        AboutPanel.present()
    }

    private func applyHotkeys() {
        let preferences = Preferences()
        hotkeyManager.update(preferences.toggleSleeveHotkey, for: .toggleSleeve)
        hotkeyManager.update(preferences.openPopoverHotkey, for: .openPopover)
    }

    private func persistHotkey(_ hotkey: Hotkey?, for action: HotkeyAction) {
        var preferences = Preferences()
        switch action {
        case .toggleSleeve: preferences.toggleSleeveHotkey = hotkey
        case .openPopover: preferences.openPopoverHotkey = hotkey
        }
        hotkeyManager.update(hotkey, for: action)
    }

    private func openSettings() {
        popover.close()
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController(
                onAutoHideSettingsChanged: { [weak self] in
                    self?.statusBar?.refreshAutoHideSchedule()
                },
                onHotkeyChanged: { [weak self] action, hotkey in
                    self?.persistHotkey(hotkey, for: action)
                },
                onRecordingActiveChanged: { [weak self] active in
                    if active {
                        self?.hotkeyManager.suspendAll()
                    } else {
                        self?.hotkeyManager.resumeAll()
                    }
                },
                onMenuBarAppearanceChanged: { [weak self] in
                    self?.statusBar?.refreshAppearance()
                }
            )
        }
        preferencesWindow?.present()
    }
}
