import AppKit

/// Presents the standard macOS About panel, customised with a tagline and a
/// clickable GitHub mark. The app icon, name, and version come from the bundle.
enum AboutPanel {
    static let repositoryURL: URL = {
        guard let url = URL(string: "https://github.com/thanhhaudev/sleev") else {
            preconditionFailure("Invalid repository URL")
        }
        return url
    }()

    static func present() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits, .version: ""])
    }

    /// Tagline followed by the GitHub mark, which links to the repository.
    private static var credits: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let text = NSMutableAttributedString(
            string: "One click hides half the menu bar. Another brings it back.\n\n",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: paragraph
            ]
        )

        if let mark = githubMark {
            let attachment = NSTextAttachment()
            attachment.image = mark
            attachment.bounds = CGRect(origin: .zero, size: mark.size)
            let icon = NSMutableAttributedString(attachment: attachment)
            icon.addAttributes(
                [.link: repositoryURL, .paragraphStyle: paragraph],
                range: NSRange(location: 0, length: icon.length)
            )
            text.append(icon)
        }

        return text
    }

    /// The GitHub mark asset, tinted so it reads on a light or dark panel.
    private static var githubMark: NSImage? {
        guard let base = NSImage(named: "github") else { return nil }
        let size = NSSize(width: 18, height: 18)
        return NSImage(size: size, flipped: false) { rect in
            base.draw(in: rect)
            NSColor.secondaryLabelColor.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}
