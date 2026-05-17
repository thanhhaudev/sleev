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
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 420))
        container.wantsLayer = true
        addEffectView(to: container)

        let mainStack = buildMainStack()
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mainStack)

        let footerView = buildFooterView()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(footerView)

        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            mainStack.widthAnchor.constraint(equalToConstant: 460),

            footerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            footerView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let logoSize = SleeveGlyph.naturalSize(forHeight: 40)
        logoImageView.image = SleeveGlyph.image(
            height: 40,
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
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: container.topAnchor),
            blur.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func buildMainStack() -> NSStackView {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.imageScaling = .scaleProportionallyUpOrDown

        let logoSize = SleeveGlyph.naturalSize(forHeight: 40)
        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 40),
            logoImageView.widthAnchor.constraint(equalToConstant: logoSize.width)
        ])

        let titleLabel = makeLabel(
            text: "sleev needs Accessibility access",
            font: .systemFont(ofSize: 26, weight: .bold)
        )
        titleLabel.alignment = .center

        let bodyLabel = makeLabel(
            text: "Allow to rearrange menubar icons on your behalf.",
            font: .systemFont(ofSize: 13)
        )
        bodyLabel.textColor = .secondaryLabelColor
        bodyLabel.alignment = .center
        bodyLabel.maximumNumberOfLines = 1

        let buttonStack = buildButtonStack()

        let stack = NSStackView(views: [logoImageView, titleLabel, bodyLabel, buttonStack])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.setCustomSpacing(24, after: bodyLabel)
        return stack
    }

    private func buildButtonStack() -> NSStackView {
        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quit))
        quitButton.bezelStyle = .rounded
        quitButton.controlSize = .large

        let openButton = NSButton(title: "Open System Settings", target: self, action: #selector(openSettings))
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"
        openButton.controlSize = .large

        let stack = NSStackView(views: [quitButton, openButton])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12
        return stack
    }

    private func buildFooterView() -> NSStackView {
        let shieldImageView = NSImageView()
        shieldImageView.image = NSImage(systemSymbolName: "checkmark.shield", accessibilityDescription: nil)
        shieldImageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        shieldImageView.contentTintColor = .tertiaryLabelColor
        shieldImageView.translatesAutoresizingMaskIntoConstraints = false

        let footerLabel = makeLabel(
            text: "Privacy-safe. sleev only reads menubar layout, never your content.",
            font: .systemFont(ofSize: 11)
        )
        footerLabel.textColor = .tertiaryLabelColor
        footerLabel.maximumNumberOfLines = 1

        let stack = NSStackView(views: [shieldImageView, footerLabel])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6
        return stack
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
