import Carbon
import SleevCore

/// The global-hotkey-bound actions. The raw value is used as the Carbon
/// `EventHotKeyID.id`, so a pressed hotkey is routed back to its action.
enum HotkeyAction: UInt32, CaseIterable {
    case toggleSleeve = 1
    case openPopover = 2
}

/// Registers global hotkeys with Carbon and routes presses to `onPressed`.
@MainActor
final class HotkeyManager {
    var onPressed: ((HotkeyAction) -> Void)?

    private var registered: [HotkeyAction: EventHotKeyRef] = [:]
    private var handlerRef: EventHandlerRef?
    private static let signature: OSType = 0x736C_6576 // 'slev'

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetEventDispatcherTarget(),
            hotkeyEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
    }

    /// Unregisters the action's current hotkey (if any) and registers `hotkey`.
    func update(_ hotkey: Hotkey?, for action: HotkeyAction) {
        if let existing = registered[action] {
            UnregisterEventHotKey(existing)
            registered[action] = nil
        }
        guard let hotkey else { return }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: action.rawValue)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.carbonModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &ref
        )
        if status == noErr, let ref {
            registered[action] = ref
        } else {
            Log.statusBar.error("Hotkey registration failed for action \(action.rawValue) (status=\(status))")
        }
    }
}

/// Carbon C callback — bridges back to the `HotkeyManager` instance via the
/// `userData` pointer, then dispatches on the main actor (the Carbon hot-key
/// handler already runs on the main event loop).
private func hotkeyEventHandler(
    _: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr, let action = HotkeyAction(rawValue: hotKeyID.id) else {
        return OSStatus(eventNotHandledErr)
    }

    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    MainActor.assumeIsolated {
        manager.onPressed?(action)
    }
    return noErr
}
