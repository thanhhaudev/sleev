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
    private var handleWidthConstraint: NSLayoutConstraint?
    private var handleHeightConstraint: NSLayoutConstraint?

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
        let naturalSize = SleeveGlyph.naturalSize(
            forHeight: CGFloat(preferences.menuBarHandleSize),
            showsPill: preferences.menuBarShowPill,
            showsDots: preferences.menuBarShowDots,
            showsChevron: preferences.menuBarShowChevron
        )
        self.handle = bar.statusItem(withLength: naturalSize.width)
        self.separator = bar.statusItem(withLength: CollapseLengthCalculator.visibleSeparatorLength(
            forDotDiameter: CGFloat(preferences.menuBarSeparatorSize)
        ))
        self.handleView = SleeveHandleView(frame: NSRect(origin: .zero, size: naturalSize))
        self.autoHide = AutoHideTimer(preferences: preferences)
        super.init()

        handleView.showsPill = preferences.menuBarShowPill
        handleView.showsDots = preferences.menuBarShowDots
        handleView.showsChevron = preferences.menuBarShowChevron

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
        separator.length = CollapseLengthCalculator.visibleSeparatorLength(
            forDotDiameter: CGFloat(Preferences().menuBarSeparatorSize)
        )
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
        collapseLength = CollapseLengthCalculator.collapseLength(forScreenWidth: widestScreenWidth)
        separator.length = collapseLength
        isCollapsed = true
        handleView.pointsLeft = false
        Log.statusBar.info("collapsed (length=\(self.collapseLength), widest=\(self.widestScreenWidth))")
        autoHide.cancel()
        onToggle?(true)
    }

    /// Points the handle chevron down while the popover is open, and restores
    /// it to the collapse/expand direction when the popover closes.
    func setPopoverOpen(_ open: Bool) {
        handleView.pointsDown = open
    }

    /// Re-arms or cancels the auto-hide countdown after the popover toggles the
    /// preference — a freshly enabled auto-hide must start counting immediately,
    /// not wait for the next expand().
    func refreshAutoHideSchedule() {
        if isCollapsed {
            autoHide.cancel()
        } else {
            autoHide.scheduleIfEnabled()
        }
    }

    /// Re-reads the menu-bar appearance preferences and rebuilds the handle.
    /// Called when the Settings window changes an appearance setting.
    func refreshAppearance() {
        let preferences = Preferences()
        applyHandleAppearance(preferences)
        applySeparatorAppearance(preferences)
    }

    private func applyHandleAppearance(_ preferences: Preferences) {
        handleView.showsPill = preferences.menuBarShowPill
        handleView.showsDots = preferences.menuBarShowDots
        handleView.showsChevron = preferences.menuBarShowChevron
        let naturalSize = SleeveGlyph.naturalSize(
            forHeight: CGFloat(preferences.menuBarHandleSize),
            showsPill: preferences.menuBarShowPill,
            showsDots: preferences.menuBarShowDots,
            showsChevron: preferences.menuBarShowChevron
        )
        handle.length = naturalSize.width
        handleWidthConstraint?.constant = naturalSize.width
        handleHeightConstraint?.constant = naturalSize.height
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
        let widthConstraint = handleView.widthAnchor.constraint(equalToConstant: naturalSize.width)
        let heightConstraint = handleView.heightAnchor.constraint(equalToConstant: naturalSize.height)
        handleWidthConstraint = widthConstraint
        handleHeightConstraint = heightConstraint
        NSLayoutConstraint.activate([
            handleView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            handleView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            widthConstraint,
            heightConstraint
        ])
    }

    private func configureSeparator() {
        separator.button?.title = ""
        applySeparatorAppearance(Preferences())
    }

    /// A round dot at the configured diameter, template-rendered so the menu
    /// bar tints it. A real image is what earns the separator a slot in the
    /// status-item row — without visible content the status item is orphaned
    /// off-screen and widening it on collapse hides nothing.
    private static func separatorDotImage(diameter: CGFloat) -> NSImage {
        let image = NSImage(
            size: NSSize(width: diameter, height: diameter),
            flipped: false
        ) { rect in
            NSColor.black.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    private func applySeparatorAppearance(_ preferences: Preferences) {
        let diameter = CGFloat(preferences.menuBarSeparatorSize)
        separator.button?.image = Self.separatorDotImage(diameter: diameter)
        separator.button?.alphaValue = CGFloat(preferences.menuBarSeparatorOpacity) / 100.0
        if !isCollapsed {
            separator.length = CollapseLengthCalculator.visibleSeparatorLength(forDotDiameter: diameter)
        }
    }

    /// Width of the widest connected display. The collapsed separator must be
    /// at least this wide to push every icon off whichever screen's menubar it
    /// lands on — multi-display setups move the menubar between screens.
    private var widestScreenWidth: CGFloat {
        NSScreen.screens.map(\.frame.width).max() ?? NSScreen.main?.frame.width ?? 1728
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
            self.collapseLength = CollapseLengthCalculator.collapseLength(
                forScreenWidth: self.widestScreenWidth
            )
            if self.isCollapsed {
                self.separator.length = self.collapseLength
            }
            Log.statusBar.info("screen change: collapseLength=\(self.collapseLength)")
        }
    }
}
