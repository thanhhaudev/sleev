import AppKit
import SwiftUI

/// Hosts the Preferences window. The app is an accessory (LSUIElement), so the
/// activation policy flips to `.regular` while the window is open and back to
/// `.accessory` when it closes — matching `OnboardingWindowController`.
@MainActor
final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    init(onAutoHideSettingsChanged: @escaping () -> Void) {
        let hosting = NSHostingController(
            rootView: PreferencesView(onAutoHideSettingsChanged: onAutoHideSettingsChanged)
        )
        // Force a layout pass so the SwiftUI content reports a real fitting
        // size; the window is then sized to it explicitly.
        hosting.view.layoutSubtreeIfNeeded()

        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable]
        window.title = "sleev Settings"
        window.isReleasedWhenClosed = false
        window.setContentSize(hosting.view.fittingSize)
        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func present() {
        NSApp.setActivationPolicy(.regular)
        if window?.isVisible == false {
            window?.center()
        }
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
