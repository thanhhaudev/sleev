import Carbon
import SleevCore

/// The global-hotkey-bound actions. The raw value is used as the Carbon
/// `EventHotKeyID.id`, so a pressed hotkey is routed back to its action —
/// do not reorder or reuse the raw values.
enum HotkeyAction: UInt32, CaseIterable {
    case toggleSleeve = 1
    case openPopover = 2
}

/// Registers global hotkeys with Carbon and routes presses to `onPressed`.
@MainActor
final class HotkeyManager {
    var onPressed: ((HotkeyAction) -> Void)?

    private var hotkeys: [HotkeyAction: Hotkey] = [:]
    private var registered: [HotkeyAction: EventHotKeyRef] = [:]
    private var handlerRef: EventHandlerRef?
    private var isSuspended = false
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

    deinit {
        for ref in registered.values {
            UnregisterEventHotKey(ref)
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
    }

    /// Sets the hotkey for an action and registers it immediately — unless a
    /// shortcut is currently being recorded (see `suspendAll()`), in which case
    /// it is stored and registered once recording finishes.
    func update(_ hotkey: Hotkey?, for action: HotkeyAction) {
        hotkeys[action] = hotkey
        unregister(action)
        if !isSuspended, let hotkey {
            register(hotkey, for: action)
        }
    }

    /// Unregisters every hotkey while a shortcut is being recorded, so the combo
    /// the user types is not also fired as an action.
    func suspendAll() {
        guard !isSuspended else { return }
        isSuspended = true
        for ref in registered.values {
            UnregisterEventHotKey(ref)
        }
        registered.removeAll()
    }

    /// Re-registers every stored hotkey once recording finishes.
    func resumeAll() {
        guard isSuspended else { return }
        isSuspended = false
        for (action, hotkey) in hotkeys {
            register(hotkey, for: action)
        }
    }

    private func register(_ hotkey: Hotkey, for action: HotkeyAction) {
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

    private func unregister(_ action: HotkeyAction) {
        if let ref = registered[action] {
            UnregisterEventHotKey(ref)
            registered[action] = nil
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
