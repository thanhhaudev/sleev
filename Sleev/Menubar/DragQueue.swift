import CoreGraphics
import Foundation
import SleevCore

public enum DragError: Error, Equatable {
    case alreadyInProgress
    case dragFailed
    case timeout
    case notControllable
}

/// Serializes drag jobs per item: rejects a duplicate while one is in flight,
/// retries once on failure, and tracks consecutive failures so the UI can warn
/// when synthetic dragging stops working.
public actor DragQueue {
    private var inFlight: Set<MenubarItem.ID> = []
    public private(set) var consecutiveFailureCount: Int = 0

    private let simulator: DragSimulating
    private let verifier: @Sendable (MenubarItem, Zone) async -> Bool
    private let retryDelayMs: UInt64

    public init(
        simulator: DragSimulating,
        verifier: @escaping @Sendable (MenubarItem, Zone) async -> Bool,
        retryDelayMs: UInt64 = 300
    ) {
        self.simulator = simulator
        self.verifier = verifier
        self.retryDelayMs = retryDelayMs
    }

    public func enqueue(
        item: MenubarItem,
        source: CGPoint,
        target: CGPoint
    ) async -> Result<Void, DragError> {
        guard item.isControllable else { return .failure(.notControllable) }
        guard !inFlight.contains(item.id) else { return .failure(.alreadyInProgress) }
        inFlight.insert(item.id)
        defer { inFlight.remove(item.id) }

        let succeeded = await attempt(item: item, source: source, target: target, isRetry: false)
        if succeeded {
            consecutiveFailureCount = 0
            return .success(())
        }

        try? await Task.sleep(nanoseconds: retryDelayMs * 1_000_000)
        let retried = await attempt(item: item, source: source, target: target, isRetry: true)
        if retried {
            consecutiveFailureCount = 0
            return .success(())
        }

        consecutiveFailureCount += 1
        return .failure(.dragFailed)
    }

    private func attempt(
        item: MenubarItem,
        source: CGPoint,
        target: CGPoint,
        isRetry: Bool
    ) async -> Bool {
        do {
            try await simulator.simulateDrag(from: source, to: target)
            let expectedZone: Zone = .sleeved
            return await verifier(item, expectedZone)
        } catch {
            let phase = isRetry ? "retry" : "first"
            let reason = error.localizedDescription
            Log.drag.error("Drag attempt \(phase, privacy: .public) failed: \(reason, privacy: .public)")
            return false
        }
    }
}
