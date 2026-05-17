import AppKit
import SleevCore

protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingViewControllerDidRequestOpenSettings(_ viewController: OnboardingViewController)
    func onboardingViewControllerDidRequestQuit(_ viewController: OnboardingViewController)
}

final class OnboardingViewController: NSViewController {
    weak var delegate: OnboardingViewControllerDelegate?

    private let logoImageView = NSImageView()

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 340))
        container.wantsLayer = true
        addEffectView(to: container)

        let contentStack = buildContentStack()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentStack)

        let buttonStack = buildButtonStack()
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(buttonStack)

        activateConstraints(contentStack: contentStack, buttonStack: buttonStack, container: container)

        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Use naturalSize so the glyph is never clipped. Do NOT set isTemplate —
        // the non-template fill respects controlAccentColor.
        let logoSize = SleeveGlyph.naturalSize(forHeight: 36)
        logoImageView.image = SleeveGlyph.image(
            height: 36,
            color: NSColor.controlAccentColor,
            trianglePointsLeft: true
        )
        logoImageView.setFrameSize(logoSize)
    }

    // MARK: - Layout helpers

    private func addEffectView(to container: NSView) {
        let blur = NSVisualEffectView()
        blur.material = .windowBackground
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(blur)
        // Pin to all edges — we want blur to fill including under the titlebar.
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: container.topAnchor),
            blur.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func buildContentStack() -> NSStackView {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.imageScaling = .scaleProportionallyUpOrDown

        let titleLabel = makeLabel(
            text: "sleev needs Accessibility access",
            font: .systemFont(ofSize: 26, weight: .bold)
        )
        titleLabel.alignment = .left

        let bodyLabel = makeLabel(
            text: """
            sleev rearranges menubar icons on your behalf and needs Accessibility \
            permission to do so. Open System Settings → Privacy & Security → \
            Accessibility, then enable sleev.
            """,
            font: .systemFont(ofSize: 13)
        )
        bodyLabel.textColor = .secondaryLabelColor
        bodyLabel.maximumNumberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.usesSingleLineMode = false
        bodyLabel.cell?.wraps = true
        bodyLabel.cell?.isScrollable = false
        bodyLabel.alignment = .left
        bodyLabel.preferredMaxLayoutWidth = 400
        bodyLabel.widthAnchor.constraint(equalToConstant: 400).isActive = true
        bodyLabel.setContentHuggingPriority(.required, for: .vertical)

        let stack = NSStackView(views: [logoImageView, titleLabel, bodyLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .gravityAreas
        stack.spacing = 16
        stack.setCustomSpacing(20, after: logoImageView)
        stack.setCustomSpacing(10, after: titleLabel)
        return stack
    }

    private func buildButtonStack() -> NSStackView {
        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quit))
        quitButton.bezelStyle = .rounded

        let openButton = NSButton(title: "Open System Settings", target: self, action: #selector(openSettings))
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"

        let stack = NSStackView(views: [quitButton, openButton])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12
        return stack
    }

    private func activateConstraints(contentStack: NSStackView, buttonStack: NSStackView, container: NSView) {
        let logoSize = SleeveGlyph.naturalSize(forHeight: 36)
        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 36),
            logoImageView.widthAnchor.constraint(equalToConstant: logoSize.width),

            // Content stack: centered horizontally, fixed 400pt wide, clears traffic lights.
            contentStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 64),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: buttonStack.topAnchor, constant: -28),
            contentStack.widthAnchor.constraint(equalToConstant: 400),

            // Button stack: pinned to bottom-right corner.
            buttonStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            buttonStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24)
        ])
    }

    private func makeLabel(text: String, font: NSFont) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    // MARK: - Actions

    @objc private func openSettings() {
        delegate?.onboardingViewControllerDidRequestOpenSettings(self)
    }

    @objc private func quit() {
        delegate?.onboardingViewControllerDidRequestQuit(self)
    }
}
