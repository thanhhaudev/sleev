import AppKit
import SwiftUI

@MainActor
public final class PopoverPresenter: NSObject {
    private let popover = NSPopover()

    override public init() {
        super.init()
        popover.behavior = .transient
        popover.animates = true
    }

    public func show(
        relativeTo button: NSStatusBarButton,
        rootView: some View
    ) {
        if popover.isShown {
            popover.close()
            return
        }
        popover.contentViewController = NSHostingController(rootView: rootView)
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
    }

    public func close() {
        if popover.isShown {
            popover.close()
        }
    }

    public var isShown: Bool {
        popover.isShown
    }
}
