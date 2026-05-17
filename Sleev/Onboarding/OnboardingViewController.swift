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
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 420))
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
        logoImageView.image = SleeveGlyph.image(
            size: NSSize(width: 88, height: 56),
            color: NSColor.controlAccentColor,
            trianglePointsLeft: true
        )
        // The non-template fill respects controlAccentColor; do NOT set isTemplate.
    }

    // MARK: - Layout helpers

    private func addEffectView(to container: NSView) {
        let effectView = NSVisualEffectView(frame: container.bounds)
        effectView.material = .windowBackground
        effectView.blendingMode = .behindWindow
        effectView.autoresizingMask = [.width, .height]
        container.addSubview(effectView)
    }

    private func buildContentStack() -> NSStackView {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.imageScaling = .scaleProportionallyUpOrDown

        let titleLabel = makeLabel(
            text: "sleev needs Accessibility access",
            font: .systemFont(ofSize: 22, weight: .semibold)
        )

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
        bodyLabel.alignment = .center
        bodyLabel.preferredMaxLayoutWidth = 380

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
        stack.spacing = 12
        return stack
    }

    private func activateConstraints(vstack: NSStackView, container: NSView) {
        let buttonStack = vstack.views.last as? NSStackView
        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 56),
            logoImageView.widthAnchor.constraint(equalToConstant: 88),
            vstack.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            vstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            vstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),
            vstack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24)
        ])
        if let buttonStack {
            NSLayoutConstraint.activate([
                buttonStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28)
            ])
        }
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
