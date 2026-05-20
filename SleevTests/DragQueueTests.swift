@testable import Sleev
import XCTest

actor MockDragSimulator: DragSimulating {
    var responses: [Result<Void, Error>] = []
    var calls: [(from: CGPoint, to: CGPoint)] = []

    func simulateDrag(from source: CGPoint, to target: CGPoint) async throws {
        calls.append((source, target))
        let response = responses.isEmpty ? .success(()) : responses.removeFirst()
        switch response {
        case .success: return
        case let .failure(error): throw error
        }
    }

    func appendResponse(_ response: Result<Void, Error>) {
        responses.append(response)
    }
}

final class DragQueueTests: XCTestCase {
    func test_singleDragSuccess() async {
        let simulator = MockDragSimulator()
        let queue = DragQueue(simulator: simulator, verifier: { _, _ in true })
        let item = makeItem(id: "spotify")
        let result = await queue.enqueue(item: item, source: .zero, target: .init(x: 100, y: 0))
        guard case .success = result else { return XCTFail("Expected success") }
        let calls = await simulator.calls
        XCTAssertEqual(calls.count, 1)
    }

    func test_duplicateEnqueueRejected() async {
        let simulator = MockDragSimulator()
        await simulator.appendResponse(.success(()))
        let queue = DragQueue(simulator: simulator, verifier: { _, _ in
            // Slow verifier to keep the first job "in flight"
            try? await Task.sleep(nanoseconds: 200_000_000)
            return true
        })
        let item = makeItem(id: "spotify")
        async let first: Result<Void, DragError> = queue.enqueue(
            item: item, source: .zero, target: .init(x: 1, y: 0)
        )
        try? await Task.sleep(nanoseconds: 20_000_000)
        let second = await queue.enqueue(item: item, source: .zero, target: .init(x: 1, y: 0))
        _ = await first
        guard case .failure(.alreadyInProgress) = second else {
            return XCTFail("Expected .alreadyInProgress, got \(second)")
        }
    }

    func test_retryAfterFailure() async {
        let simulator = MockDragSimulator()
        await simulator.appendResponse(.failure(DragSimulatorError.eventPostFailed))
        await simulator.appendResponse(.success(()))
        let queue = DragQueue(simulator: simulator, verifier: { _, _ in true })
        let item = makeItem(id: "spotify")
        let result = await queue.enqueue(item: item, source: .zero, target: .init(x: 1, y: 0))
        guard case .success = result else { return XCTFail("Expected success after retry") }
        let calls = await simulator.calls
        XCTAssertEqual(calls.count, 2)
    }

    func test_bothAttemptsFailReturnsDragFailed() async {
        let simulator = MockDragSimulator()
        await simulator.appendResponse(.failure(DragSimulatorError.eventPostFailed))
        await simulator.appendResponse(.failure(DragSimulatorError.eventPostFailed))
        let queue = DragQueue(simulator: simulator, verifier: { _, _ in true })
        let item = makeItem(id: "spotify")
        let result = await queue.enqueue(item: item, source: .zero, target: .init(x: 1, y: 0))
        guard case .failure(.dragFailed) = result else {
            return XCTFail("Expected .dragFailed, got \(result)")
        }
    }

    func test_consecutiveFailuresIncrementCounter() async {
        let simulator = MockDragSimulator()
        await simulator.appendResponse(.failure(DragSimulatorError.eventPostFailed))
        await simulator.appendResponse(.failure(DragSimulatorError.eventPostFailed))
        let queue = DragQueue(simulator: simulator, verifier: { _, _ in true })
        let item = makeItem(id: "spotify")
        _ = await queue.enqueue(item: item, source: .zero, target: .init(x: 1, y: 0))
        let count = await queue.consecutiveFailureCount
        XCTAssertEqual(count, 1)
    }

    func test_consecutiveFailuresResetOnSuccess() async {
        let simulator = MockDragSimulator()
        await simulator.appendResponse(.failure(DragSimulatorError.eventPostFailed))
        await simulator.appendResponse(.failure(DragSimulatorError.eventPostFailed))
        let queue = DragQueue(simulator: simulator, verifier: { _, _ in true })
        let item = makeItem(id: "spotify")
        _ = await queue.enqueue(item: item, source: .zero, target: .init(x: 1, y: 0))
        await simulator.appendResponse(.success(()))
        let secondItem = makeItem(id: "slack")
        _ = await queue.enqueue(item: secondItem, source: .zero, target: .init(x: 1, y: 0))
        let count = await queue.consecutiveFailureCount
        XCTAssertEqual(count, 0)
    }

    // MARK: helpers

    private func makeItem(id: String) -> MenubarItem {
        MenubarItem(
            id: id, bundleID: id, displayName: id, icon: nil,
            frame: .zero, zone: .visible, isControllable: true
        )
    }
}
