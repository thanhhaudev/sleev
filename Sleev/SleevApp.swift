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
    private var inventory: MenubarInventory!
    private var popover: PopoverPresenter!
    private var inFlightIDs: Set<MenubarItem.ID> = []
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
            inFlightIDs: Binding(
                get: { self.inFlightIDs },
                set: { self.inFlightIDs = $0 }
            ),
            isAutoHideEnabled: preferences.autoHideEnabled,
            onCardTap: { [weak self] item in self?.handleCardTap(item: item) },
            onToggleAutoHide: { [weak self] in self?.toggleAutoHide() },
            onQuit: { NSApp.terminate(nil) }
        )
        popover.show(relativeTo: button, rootView: root)
    }

    private func handleCardTap(item: MenubarItem) {
        // M4-3 wires this to the drag queue. For M3-4 (UI shell), just flip zone
        // in the inventory so the visual state changes — no real drag.
        let next: Zone = item.zone == .visible ? .sleeved : .visible
        inventory.setZone(next, forItemID: item.id)
        Log.app.info("[stub] card tapped: \(item.displayName, privacy: .public) → \(next.rawValue)")
    }

    private func toggleAutoHide() {
        preferences.autoHideEnabled.toggle()
        Log.app.info("autoHide.enabled toggled -> \(self.preferences.autoHideEnabled)")
    }

    private func refreshInventory() {
        let enumerator = self.enumerator
        Task { [weak self] in
            let items = await Task.detached(priority: .userInitiated) {
                enumerator.enumerate()
            }.value
            guard let self else { return }
            self.inventory.apply(liveItems: items)
            Log.app.info("inventory refreshed: \(items.count) items")
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
