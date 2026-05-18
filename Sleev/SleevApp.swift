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
    private var inventory: MenubarInventory!
    private var popover: PopoverPresenter!
    private var inFlightIDs: Set<MenubarItem.ID> = []
    private var statusBar: StatusBarController?
    private var runMode: RunMode = .real
    private var pollTimer: Timer?
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
        loadStubInventory()
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

    private func loadStubInventory() {
        // Stub items for visual review. Replaced by MenubarEnumerator in M3-5.
        inventory.apply(liveItems: makeStubItems())
    }

    // swiftlint:disable:next function_body_length
    private func makeStubItems() -> [MenubarItem] {
        [
            MenubarItem(
                id: "stub.spotify",
                bundleID: "com.spotify.client",
                displayName: "Spotify",
                icon: stubIcon("music.note"),
                frame: .zero,
                zone: .visible,
                isControllable: true
            ),
            MenubarItem(
                id: "stub.slack",
                bundleID: "com.tinyspeck.slackmacgap",
                displayName: "Slack",
                icon: stubIcon("number"),
                frame: .zero,
                zone: .visible,
                isControllable: true
            ),
            MenubarItem(
                id: "stub.figma",
                bundleID: "com.figma.Desktop",
                displayName: "Figma",
                icon: stubIcon("paintpalette"),
                frame: .zero,
                zone: .sleeved,
                isControllable: true
            ),
            MenubarItem(
                id: "stub.notion",
                bundleID: "notion.id",
                displayName: "Notion",
                icon: stubIcon("note.text"),
                frame: .zero,
                zone: .visible,
                isControllable: true
            ),
            MenubarItem(
                id: "stub.linear",
                bundleID: "com.linear",
                displayName: "Linear",
                icon: stubIcon("chart.bar.doc.horizontal"),
                frame: .zero,
                zone: .sleeved,
                isControllable: true
            ),
            MenubarItem(
                id: "stub.wifi",
                bundleID: "com.apple.controlcenter.wifi",
                displayName: "Wi-Fi",
                icon: stubIcon("wifi"),
                frame: .zero,
                zone: .visible,
                isControllable: false
            ),
            MenubarItem(
                id: "stub.battery",
                bundleID: "com.apple.controlcenter.battery",
                displayName: "Battery",
                icon: stubIcon("battery.75"),
                frame: .zero,
                zone: .visible,
                isControllable: false
            )
        ]
    }

    private func stubIcon(_ symbolName: String) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
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
        loadStubInventory()
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
