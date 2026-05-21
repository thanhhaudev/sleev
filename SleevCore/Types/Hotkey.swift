import Foundation

/// A recorded global keyboard shortcut. `carbonModifiers` is a Carbon modifier
/// mask (`cmdKey` / `optionKey` / `controlKey` / `shiftKey`); `displayString`
/// is composed when the shortcut is recorded so display needs no key-code
/// translation.
public struct Hotkey: Codable, Equatable {
    public let keyCode: UInt32
    public let carbonModifiers: UInt32
    public let displayString: String

    public init(keyCode: UInt32, carbonModifiers: UInt32, displayString: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.displayString = displayString
    }
}
