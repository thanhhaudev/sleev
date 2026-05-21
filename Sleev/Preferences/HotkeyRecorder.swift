import AppKit
import Carbon
import SleevCore
import SwiftUI

/// A control for recording a global keyboard shortcut, styled like the native
/// macOS Settings shortcut field: at rest it shows the combo (or "none") as
/// plain text with no box; clicking it opens a recessed field that listens for
/// a combo with at least one of ⌘/⌥/⌃. Escape cancels, the "✕" clears, and a
/// click anywhere outside the field stops listening.
///
/// `activeRecorder` is shared across sibling recorders so only one records at a
/// time. `isDuplicate` rejects a combo already bound to the other recorder —
/// the field flashes red and keeps listening. `onRecordingChanged` reports when
/// recording starts and stops, so the app can pause its global hotkeys while a
/// combo is being typed.
struct HotkeyRecorder<ID: Hashable>: View {
    let id: ID
    @Binding var activeRecorder: ID?
    let hotkey: Hotkey?
    let isDuplicate: (Hotkey) -> Bool
    let onRecordingChanged: (Bool) -> Void
    let onChange: (Hotkey?) -> Void

    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var caretVisible = true
    @State private var conflict = false
    @State private var fieldFrame: CGRect = .zero

    var body: some View {
        Group {
            if isRecording {
                recordingField
            } else {
                restingLabel
            }
        }
        .onDisappear { stopRecording() }
        .onChange(of: activeRecorder) { _, newValue in
            if newValue != id, isRecording { stopRecording() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            if isRecording { stopRecording() }
        }
    }

    private var restingLabel: some View {
        Text(hotkey?.displayString ?? "none")
            .foregroundStyle(hotkey == nil ? .secondary : .primary)
            .frame(minWidth: 72, minHeight: 24, alignment: .trailing)
            .contentShape(Rectangle())
            .onTapGesture { startRecording() }
            .help("Click to record a shortcut")
    }

    private var recordingField: some View {
        HStack(spacing: 6) {
            Button { clearShortcut() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear shortcut")

            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(fieldBorder, lineWidth: 1)
                Text("|")
                    .foregroundStyle(.secondary)
                    .opacity(caretVisible ? 1 : 0)
                    .padding(.trailing, 8)
            }
            .frame(width: 84, height: 24)
            .contentShape(Rectangle())
            .onTapGesture { stopRecording() }
        }
        .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }, action: { fieldFrame = $0 })
    }

    private var fieldBorder: Color {
        conflict ? Color.red.opacity(0.9) : Color(nsColor: .separatorColor)
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        conflict = false
        activeRecorder = id
        caretVisible = true
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            caretVisible = false
        }
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown]
        ) { event in
            if event.type == .keyDown {
                handleRecordingEvent(event)
                return nil
            }
            stopIfClickOutside(event)
            return event
        }
        onRecordingChanged(true)
    }

    private func stopRecording() {
        let wasRecording = isRecording
        isRecording = false
        conflict = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        if activeRecorder == id {
            activeRecorder = nil
        }
        if wasRecording {
            onRecordingChanged(false)
        }
    }

    private func clearShortcut() {
        onChange(nil)
        stopRecording()
    }

    /// Stops recording when a mouse-down lands anywhere outside the field — its
    /// own taps (the field, the "✕") fall inside `fieldFrame` and are left to
    /// their own handlers.
    private func stopIfClickOutside(_ event: NSEvent) {
        guard let contentView = event.window?.contentView else {
            stopRecording()
            return
        }
        let location = event.locationInWindow
        let point = CGPoint(x: location.x, y: contentView.bounds.height - location.y)
        if !fieldFrame.contains(point) {
            stopRecording()
        }
    }

    private func handleRecordingEvent(_ event: NSEvent) {
        conflict = false
        if event.keyCode == UInt16(kVK_Escape) {
            stopRecording()
            return
        }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasRequiredModifier =
            flags.contains(.command) || flags.contains(.option) || flags.contains(.control)
        guard hasRequiredModifier else { return }

        let recorded = Hotkey(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: carbonModifiers(from: flags),
            displayString: displayString(for: flags, event: event)
        )
        guard !isDuplicate(recorded) else {
            withAnimation(.easeInOut(duration: 0.12)) { conflict = true }
            return
        }
        stopRecording()
        onChange(recorded)
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mask: UInt32 = 0
        if flags.contains(.command) { mask |= UInt32(cmdKey) }
        if flags.contains(.option) { mask |= UInt32(optionKey) }
        if flags.contains(.control) { mask |= UInt32(controlKey) }
        if flags.contains(.shift) { mask |= UInt32(shiftKey) }
        return mask
    }

    private func displayString(for flags: NSEvent.ModifierFlags, event: NSEvent) -> String {
        var result = ""
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }
        return result + (event.charactersIgnoringModifiers?.uppercased() ?? "")
    }
}
