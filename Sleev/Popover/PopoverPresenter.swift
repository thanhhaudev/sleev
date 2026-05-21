import AppKit
import SwiftUI

/// Floating popover-style window anchored below a status item button.
/// Replaces NSPopover, which has positioning bugs on notched MacBooks where
/// `button.bounds` extends down into the menubar shadow zone.
@MainActor
public final class PopoverPresenter: NSObject {
    private var window: NSWindow?
    private var clickMonitor: Any?
    private var escapeMonitor: Any?
    private var windowMoveObservers: [NSObjectProtocol] = []

    public private(set) var isShown: Bool = false

    /// Fired with `true` when the popover becomes visible and `false` when it
    /// closes. SleevApp uses this to point the handle chevron down while open.
    public var onVisibilityChanged: ((Bool) -> Void)?

    override public init() {
        super.init()
    }

    public func show(
        relativeTo button: NSStatusBarButton,
        alsoDismissOnUserDragOf extraWindows: [NSWindow] = [],
        rootView: some View
    ) {
        if isShown {
            close()
            return
        }
        guard let buttonWindow = button.window else { return }

        // Build the hosting window.
        let hosting = NSHostingController(rootView: rootView)
        hosting.view.layoutSubtreeIfNeeded()
        let contentSize = hosting.view.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView:
            RoundedContainer { rootView }
        )

        // Compute position: horizontally centered under the chevron, vertically
        // immediately below the menubar on the active screen.
        let buttonFrameInScreen = buttonWindow.convertToScreen(
            button.convert(button.bounds, to: nil)
        )
        let screen = buttonWindow.screen ?? NSScreen.main
        let menubarBottom = (screen?.visibleFrame.maxY) ?? buttonFrameInScreen.minY

        let originX = buttonFrameInScreen.midX - contentSize.width / 2
        let originY = menubarBottom - contentSize.height - 6 // 6pt gap

        // Clamp X so the window doesn't overflow the screen edges.
        let screenFrame = screen?.frame ?? buttonFrameInScreen
        let clampedX = min(
            max(originX, screenFrame.minX + 6),
            screenFrame.maxX - contentSize.width - 6
        )

        panel.setFrameOrigin(NSPoint(x: clampedX, y: originY))
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 1
        }

        window = panel
        isShown = true
        let dragWindows = extraWindows + [button.window].compactMap { $0 }
        installEventMonitors(dragWindows: dragWindows)
        onVisibilityChanged?(true)
    }

    public func close() {
        guard let panel = window else { return }
        removeEventMonitors()
        onVisibilityChanged?(false)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.1
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                panel.orderOut(nil)
                self?.window = nil
                self?.isShown = false
            }
        }
    }

    // MARK: - Event monitors

    private func installEventMonitors(dragWindows: [NSWindow]) {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            // Ignore sleev's own synthetic drag events; they would otherwise
            // dismiss the popover mid-drag.
            if event.cgEvent?.getIntegerValueField(.eventSourceUserData) == DragSimulator.syntheticEventTag {
                return
            }
            DispatchQueue.main.async { self?.close() }
        }
        escapeMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown]
        ) { [weak self] event in
            if event.keyCode == 53 { // Escape
                DispatchQueue.main.async { self?.close() }
                return nil
            }
            return event
        }
        // Close when the user drags one of sleev's status items. The window
        // also moves on automatic menu bar relayouts, so a move only counts
        // as a user drag when a mouse button is currently held.
        for movedWindow in dragWindows {
            let observer = NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification,
                object: movedWindow,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard NSEvent.pressedMouseButtons != 0 else { return }
                    self?.close()
                }
            }
            windowMoveObservers.append(observer)
        }
    }

    private func removeEventMonitors() {
        if let token = clickMonitor {
            NSEvent.removeMonitor(token)
            clickMonitor = nil
        }
        if let token = escapeMonitor {
            NSEvent.removeMonitor(token)
            escapeMonitor = nil
        }
        for observer in windowMoveObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        windowMoveObservers.removeAll()
    }
}

/// Wraps the SwiftUI content with rounded corners + subtle border so the
/// borderless NSWindow looks like a proper macOS popover. The visual matches
/// what NSPopover would have rendered.
private struct RoundedContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
