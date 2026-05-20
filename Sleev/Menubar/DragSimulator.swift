import AppKit
import CoreGraphics
import Foundation
import SleevCore

public enum DragSimulatorError: Error {
    case noEventSource
    case eventPostFailed
}

public protocol DragSimulating: Sendable {
    func simulateDrag(from source: CGPoint, to target: CGPoint) async throws
}

/// Posts a synthetic ⌘+drag via CGEvent to move a menubar icon.
/// macOS only permits rearranging menubar extras while ⌘ is held.
public final class DragSimulator: DragSimulating {
    /// Stamped onto every synthetic event's `eventSourceUserData` field so
    /// other components (e.g. the popover's click monitor) can tell sleev's
    /// own events apart from genuine user input.
    public static let syntheticEventTag: Int64 = 0xC0DE

    private let stepCount = 10
    private let stepDelayMicroseconds: UInt32 = 15000

    public init() {}

    public func simulateDrag(from source: CGPoint, to target: CGPoint) async throws {
        guard let cgSource = CGEventSource(stateID: .combinedSessionState) else {
            throw DragSimulatorError.noEventSource
        }

        // Press ⌘.
        try postKey(.command, down: true, source: cgSource)
        try await Task.sleep(nanoseconds: 30_000_000) // 30ms

        // Mouse down at source with ⌘ held.
        try postMouse(.leftMouseDown, at: source, flags: .maskCommand, source: cgSource)

        // Smooth drag.
        for index in 1 ... stepCount {
            let progress = Double(index) / Double(stepCount)
            let point = CGPoint(
                x: source.x + (target.x - source.x) * progress,
                y: source.y + (target.y - source.y) * progress
            )
            try postMouse(.leftMouseDragged, at: point, flags: .maskCommand, source: cgSource)
            try await Task.sleep(nanoseconds: UInt64(stepDelayMicroseconds) * 1000)
        }

        // Mouse up at target.
        try postMouse(.leftMouseUp, at: target, flags: .maskCommand, source: cgSource)

        // Release ⌘.
        try await Task.sleep(nanoseconds: 30_000_000)
        try postKey(.command, down: false, source: cgSource)

        // Let macOS settle.
        try await Task.sleep(nanoseconds: 250_000_000)
    }

    private func postKey(_ key: CGKeyCode, down: Bool, source: CGEventSource) throws {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down) else {
            throw DragSimulatorError.eventPostFailed
        }
        event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventTag)
        event.post(tap: .cgSessionEventTap)
    }

    private func postMouse(
        _ type: CGEventType,
        at point: CGPoint,
        flags: CGEventFlags,
        source: CGEventSource
    ) throws {
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            throw DragSimulatorError.eventPostFailed
        }
        event.flags = flags
        event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventTag)
        event.post(tap: .cgSessionEventTap)
    }
}

extension CGKeyCode {
    /// macOS virtual key code for the left Command key.
    static var command: CGKeyCode {
        0x37
    }
}
