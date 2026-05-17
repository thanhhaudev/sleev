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
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 380))
        container.wantsLayer = true
        addEffectView(to: container)

        let vstack = buildContentStack()
        vstack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(vstack)
        activateConstraints(vstack: vstack, container: container)

        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Use naturalSize so the glyph is never clipped. Do NOT set isTemplate —
        // the non-template fill respects controlAccentColor.
        let logoSize = SleeveGlyph.naturalSize(forHeight: 60)
        logoImageView.image = SleeveGlyph.image(
            height: 60,
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
            font: .systemFont(ofSize: 22, weight: .semibold)
        )
        titleLabel.alignment = .center

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
        bodyLabel.preferredMaxLayoutWidth = 380
        bodyLabel.alignment = .center
        bodyLabel.widthAnchor.constraint(equalToConstant: 380).isActive = true
        bodyLabel.setContentHuggingPriority(.required, for: .vertical)

        let buttonStack = buildButtonStack()

        let vstack = NSStackView(views: [logoImageView, titleLabel, bodyLabel, buttonStack])
        vstack.orientation = .vertical
        vstack.alignment = .centerX
        vstack.distribution = .gravityAreas
        vstack.spacing = 0
        vstack.setCustomSpacing(24, after: logoImageView)
        vstack.setCustomSpacing(12, after: titleLabel)
        vstack.setCustomSpacing(32, after: bodyLabel)
        return vstack
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

    private func activateConstraints(vstack: NSStackView, container: NSView) {
        let logoSize = SleeveGlyph.naturalSize(forHeight: 60)
        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            logoImageView.widthAnchor.constraint(equalToConstant: logoSize.width),

            // Center vertically in the content area.
            vstack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            vstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            vstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),

            // Flexible top/bottom bounds — logo must clear the traffic-light area (56pt).
            vstack.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 56),
            vstack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -24)
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
