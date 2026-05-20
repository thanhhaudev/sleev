import AppKit
import SleevCore

/// Owns the two NSStatusItems that implement the sleeve trick:
///   - `handle`: hosts the user-clickable SleeveHandleView.
///   - `separator`: status item whose length is enlarged dramatically while collapsed,
///                  pushing every status item to its left off the visible menubar.
///
/// NSObject subclass because NSStatusBarButton target/action routes through Cocoa.
final class StatusBarController: NSObject {
    private let handle: NSStatusItem
    private let separator: NSStatusItem
    private let handleView: SleeveHandleView
    private let autoHide: AutoHideTimer
    private var screenObserver: NSObjectProtocol?

    private(set) var isCollapsed: Bool = false
    private var collapseLength: CGFloat = CollapseLengthCalculator.collapseLength(
        forScreenWidth: NSScreen.main?.frame.width ?? 1728
    )

    var onToggle: ((Bool) -> Void)?

    /// Fired when the user right-clicks (or control-clicks) the handle.
    /// SleevApp uses this to open the popover.
    var onRightClick: (() -> Void)?

    /// The status item's button — exposed for anchoring the popover window.
    var handleButton: NSStatusBarButton? {
        handle.button
    }

    /// The separator's button — exposed so drag targets can be computed
    /// relative to it. Items left of the separator are hidden on collapse.
    var separatorButton: NSStatusBarButton? {
        separator.button
    }

    init(preferences: Preferences = Preferences()) {
        let bar = NSStatusBar.system
        let naturalSize = SleeveGlyph.naturalSize(forHeight: 14, wrapped: true)
        self.handle = bar.statusItem(withLength: naturalSize.width)
        self.separator = bar.statusItem(withLength: CollapseLengthCalculator.visibleSeparatorLength)
        self.handleView = SleeveHandleView(frame: NSRect(origin: .zero, size: naturalSize))
        self.autoHide = AutoHideTimer(preferences: preferences)
        super.init()

        configureHandle(naturalSize: naturalSize)
        configureSeparator()
        observeScreenChanges()

        handle.autosaveName = "sleev.handle"
        separator.autosaveName = "sleev.separator"

        autoHide.onFire = { [weak self] in self?.collapse() }
        autoHide.scheduleIfEnabled()
        handleView.pointsLeft = !isCollapsed
    }

    deinit {
        if let token = screenObserver { NotificationCenter.default.removeObserver(token) }
        NSStatusBar.system.removeStatusItem(handle)
        NSStatusBar.system.removeStatusItem(separator)
    }

    // MARK: - Public

    func toggle() {
        if isCollapsed {
            expand()
        } else {
            collapse()
        }
    }

    func expand() {
        guard isCollapsed else { return }
        separator.length = CollapseLengthCalculator.visibleSeparatorLength
        isCollapsed = false
        handleView.pointsLeft = true
        Log.statusBar.info("expanded")
        autoHide.scheduleIfEnabled()
        onToggle?(false)
    }

    func collapse() {
        guard !isCollapsed else { return }
        guard isHandleRightOfSeparator else {
            Log.statusBar.notice("collapse skipped: handle is not right of separator")
            return
        }
        separator.length = collapseLength
        isCollapsed = true
        handleView.pointsLeft = false
        Log.statusBar.info("collapsed (length=\(self.collapseLength))")
        autoHide.cancel()
        onToggle?(true)
    }

    /// Points the handle chevron down while the popover is open, and restores
    /// it to the collapse/expand direction when the popover closes.
    func setPopoverOpen(_ open: Bool) {
        handleView.pointsDown = open
    }

    // MARK: - Setup

    private func configureHandle(naturalSize: NSSize) {
        guard let button = handle.button else { return }
        button.target = self
        button.action = #selector(handlePressed)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.image = nil
        handleView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(handleView)
        NSLayoutConstraint.activate([
            handleView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            handleView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            handleView.widthAnchor.constraint(equalToConstant: naturalSize.width),
            handleView.heightAnchor.constraint(equalToConstant: naturalSize.height)
        ])
    }

    private func configureSeparator() {
        // The separator's only purpose is to occupy length; no visible content.
        separator.button?.image = nil
        separator.button?.title = ""
    }

    private var isHandleRightOfSeparator: Bool {
        guard let handleX = handle.button?.window?.frame.origin.x,
              let separatorX = separator.button?.window?.frame.origin.x
        else {
            return true
        }
        return handleX >= separatorX
    }

    // MARK: - Click routing

    @objc private func handlePressed() {
        let event = NSApp.currentEvent
        let typeRaw = event.map { Int($0.type.rawValue) } ?? -1
        let modifiers = event?.modifierFlags.rawValue ?? 0
        Log.statusBar.info("handlePressed: type=\(typeRaw), modifiers=\(modifiers)")
        guard let event else { toggle(); return }
        let isRightClick = event.type == .rightMouseUp
            || event.type == .rightMouseDown
            || event.modifierFlags.contains(.control)
        if isRightClick {
            let callbackState = self.onRightClick != nil ? "set" : "nil"
            Log.statusBar.info("handlePressed: routing to onRightClick (\(callbackState))")
            onRightClick?()
        } else {
            toggle()
        }
    }

    // MARK: - Screen change

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let width = NSScreen.main?.frame.width ?? 1728
            self.collapseLength = CollapseLengthCalculator.collapseLength(forScreenWidth: width)
            if self.isCollapsed {
                self.separator.length = self.collapseLength
            }
            Log.statusBar.info("screen change: collapseLength=\(self.collapseLength)")
        }
    }
}
