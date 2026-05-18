@testable import Sleev
import XCTest

final class MenubarItemTests: XCTestCase {
    func test_zoneCodableRoundTrip() throws {
        let original: [Zone] = [.visible, .sleeved]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([Zone].self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_menubarItemHasStableIdentifier() {
        let item = MenubarItem(
            id: "com.spotify.client",
            bundleID: "com.spotify.client",
            displayName: "Spotify",
            icon: nil,
            frame: CGRect(x: 100, y: 0, width: 22, height: 22),
            zone: .visible,
            isControllable: true
        )
        XCTAssertEqual(item.id, "com.spotify.client")
    }
}
