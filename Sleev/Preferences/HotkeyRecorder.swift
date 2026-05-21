import AppKit
import Carbon
import SleevCore
import SwiftUI

/// A field-style control for recording a global keyboard shortcut. Click the
/// field to record; press a combo with at least one of ⌘/⌥/⌃; Escape cancels;
/// the "✕" clears a recorded shortcut.
struct HotkeyRecorder: View {
    let hotkey: Hotkey?
    let onChange: (Hotkey?) -> Void

    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var caretVisible = true

    var body: some View {
        HStack(spacing: 6) {
            field
            if hotkey != nil, !isRecording {
                Button { onChange(nil) } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear shortcut")
            }
        }
        .onDisappear { stopRecording() }
    }

    private var field: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(
                    isRecording ? Color.accentColor : Color.secondary.opacity(0.4),
                    lineWidth: 1
                )
            fieldContent
        }
        .frame(width: 132, height: 24)
        .contentShape(Rectangle())
        .onTapGesture { isRecording ? stopRecording() : startRecording() }
    }

    @ViewBuilder
    private var fieldContent: some View {
        if isRecording {
            Text("|")
                .foregroundStyle(.secondary)
                .opacity(caretVisible ? 1 : 0)
        } else if let hotkey {
            Text(hotkey.displayString)
                .monospaced()
        } else {
            Color.clear
        }
    }

    private func startRecording() {
        isRecording = true
        caretVisible = true
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            caretVisible = false
        }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handleRecordingEvent(event)
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handleRecordingEvent(_ event: NSEvent) {
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
