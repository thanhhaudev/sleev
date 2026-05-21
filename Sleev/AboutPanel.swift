import AppKit

/// Presents the standard macOS About panel, customised with a tagline and a
/// GitHub link. The app icon, name, and version are filled in from the bundle.
enum AboutPanel {
    static let repositoryURL: URL = {
        guard let url = URL(string: "https://github.com/thanhhaudev/sleev") else {
            preconditionFailure("Invalid repository URL")
        }
        return url
    }()

    static func present() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }

    /// Tagline + clickable GitHub link, shown in the panel's credits area.
    private static var credits: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph
        ]

        let text = NSMutableAttributedString(
            string: "Hides the menu bar icons nobody clicks.\n\n",
            attributes: baseAttributes
        )

        var linkAttributes = baseAttributes
        linkAttributes[.link] = repositoryURL
        text.append(NSAttributedString(
            string: "github.com/thanhhaudev/sleev",
            attributes: linkAttributes
        ))

        return text
    }
}
