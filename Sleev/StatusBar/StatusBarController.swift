import AppKit
import SleevCore

/// Stub controller for M1.2: installs the visible sleeve handle + right-click menu
/// but does NOT implement the collapse/expand separator trick. M3.2 replaces this.
final class StatusBarController: NSObject {
    private let handle: NSStatusItem
    private var isPretendCollapsed = false

    override init() {
        self.handle = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configure()
        handle.autosaveName = "sleev.handle"
    }

    deinit {
        NSStatusBar.system.removeStatusItem(handle)
    }

    // MARK: - Setup

    private func configure() {
        guard let button = handle.button else { return }
        button.target = self
        button.action = #selector(handlePressed)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateImage()
    }

    private func updateImage() {
        let image = SleeveGlyph.image(
            size: NSSize(width: 22, height: 14),
            color: NSColor.labelColor,
            trianglePointsLeft: !isPretendCollapsed
        )
        image.isTemplate = true
        handle.button?.image = image
    }

    // MARK: - Actions

    @objc private func handlePressed() {
        guard let event = NSApp.currentEvent else {
            fakeToggle()
            return
        }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showContextMenu()
        } else {
            fakeToggle()
        }
    }

    private func fakeToggle() {
        isPretendCollapsed.toggle()
        Log.statusBar.info("[stub] toggle pressed (pretendCollapsed=\(self.isPretendCollapsed))")
        updateImage()
    }

    private func showContextMenu() {
        guard let button = handle.button else { return }
        let menu = buildMenu()
        let origin = NSPoint(x: 0, y: button.bounds.height + 4)
        menu.popUp(positioning: nil, at: origin, in: button)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let autoItem = NSMenuItem(
            title: "Disable Auto Collapse", // M3.2 will make this label dynamic
            action: #selector(stubAutoHide),
            keyEquivalent: "t"
        )
        autoItem.target = self
        menu.addItem(autoItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit sleev",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        return menu
    }

    @objc private func stubAutoHide() {
        Log.statusBar.info("[stub] Toggle Auto Collapse tapped")
    }
}
