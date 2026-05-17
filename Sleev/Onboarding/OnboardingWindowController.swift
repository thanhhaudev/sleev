import AppKit

final class OnboardingWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "sleev"
        window.isReleasedWhenClosed = false

        // Minimal-chrome look: transparent titlebar + clear background lets the
        // NSVisualEffectView render edge-to-edge (matches Settings.app, Books.app).
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func install(viewController: OnboardingViewController) {
        window?.contentViewController = viewController
    }

    func present() {
        NSApp.setActivationPolicy(.regular)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        close()
        NSApp.setActivationPolicy(.accessory)
    }
}
