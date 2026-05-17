import AppKit
import SleevCore

protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingViewControllerDidRequestOpenSettings(_ viewController: OnboardingViewController)
    func onboardingViewControllerDidRequestQuit(_ viewController: OnboardingViewController)
}

final class OnboardingViewController: NSViewController {
    weak var delegate: OnboardingViewControllerDelegate?

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 320))
        container.wantsLayer = true

        let titleLabel = makeLabel(
            text: "sleev needs Accessibility access",
            font: .systemFont(ofSize: 18, weight: .semibold)
        )

        let bodyLabel = makeLabel(
            text: """
            sleev rearranges menubar icons on your behalf and needs Accessibility \
            permission to do so. Open System Settings → Privacy & Security → \
            Accessibility, then enable sleev.
            """,
            font: .systemFont(ofSize: 13)
        )
        bodyLabel.maximumNumberOfLines = 0

        let openButton = NSButton(title: "Open System Settings", target: self, action: #selector(openSettings))
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"

        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quit))
        quitButton.bezelStyle = .rounded

        let buttonStack = NSStackView(views: [quitButton, openButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12

        let vstack = NSStackView(views: [titleLabel, bodyLabel, buttonStack])
        vstack.orientation = .vertical
        vstack.alignment = .leading
        vstack.spacing = 16
        vstack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(vstack)

        NSLayoutConstraint.activate([
            vstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            vstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),
            vstack.topAnchor.constraint(equalTo: container.topAnchor, constant: 28),
            vstack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -28),
            buttonStack.trailingAnchor.constraint(equalTo: vstack.trailingAnchor)
        ])

        self.view = container
    }

    private func makeLabel(text: String, font: NSFont) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    @objc private func openSettings() {
        delegate?.onboardingViewControllerDidRequestOpenSettings(self)
    }

    @objc private func quit() {
        delegate?.onboardingViewControllerDidRequestQuit(self)
    }
}
