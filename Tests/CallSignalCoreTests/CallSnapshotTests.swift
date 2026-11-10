import XCTest
@testable import CallSignalCore

final class CallSnapshotTests: XCTestCase {
    private let first = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let second = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    func testEmptySnapshotDoesNotMatchAnyRule() {
        let snapshot = CallSnapshot(calls: [])
        for rule in DetectionRule.allCases { XCTAssertFalse(snapshot.matches(rule)) }
        XCTAssertEqual(snapshot.title, "No calls observed")
    }

    func testRingingOnlyMatchesAnyActive() {
        let snapshot = CallSnapshot(calls: [ObservedCall(id: first)])
        XCTAssertTrue(snapshot.matches(.anyActive))
        XCTAssertFalse(snapshot.matches(.connected))
        XCTAssertFalse(snapshot.matches(.connectedNotHeld))
        XCTAssertEqual(snapshot.ringingCount, 1)
        XCTAssertEqual(snapshot.title, "Incoming call")
    }

    func testDialingIsNotConnected() {
        let snapshot = CallSnapshot(calls: [ObservedCall(id: first, isOutgoing: true)])
        XCTAssertEqual(snapshot.dialingCount, 1)
        XCTAssertEqual(snapshot.ringingCount, 0)
        XCTAssertFalse(snapshot.matches(.connected))
        XCTAssertEqual(snapshot.title, "Dialing")
    }

    func testConnectedMatchesEveryDefinition() {
        let snapshot = CallSnapshot(calls: [ObservedCall(id: first, hasConnected: true)])
        for rule in DetectionRule.allCases { XCTAssertTrue(snapshot.matches(rule)) }
        XCTAssertEqual(snapshot.title, "On a call")
    }

    func testHeldCallHonorsDefinition() {
        let snapshot = CallSnapshot(calls: [ObservedCall(id: first, hasConnected: true, isOnHold: true)])
        XCTAssertTrue(snapshot.matches(.connected))
        XCTAssertFalse(snapshot.matches(.connectedNotHeld))
        XCTAssertTrue(snapshot.matches(.anyActive))
        XCTAssertEqual(snapshot.heldCount, 1)
        XCTAssertEqual(snapshot.title, "Call on hold")
    }

    func testEndedCallCannotMatchEvenWithConnectedAndHoldFlags() {
        let call = ObservedCall(id: first, hasConnected: true, hasEnded: true, isOnHold: true)
        XCTAssertEqual(call.phase, .ended)
        let snapshot = CallSnapshot(calls: [call])
        XCTAssertTrue(snapshot.calls.isEmpty)
        for rule in DetectionRule.allCases { XCTAssertFalse(rule.matches(call)) }
    }

    func testActiveCallTakesPriorityOverHeldAndRingingCalls() {
        let snapshot = CallSnapshot(calls: [
            ObservedCall(id: first, hasConnected: true, isOnHold: true),
            ObservedCall(id: second, hasConnected: true),
            ObservedCall(id: UUID())
        ])
        XCTAssertEqual(snapshot.title, "On a call")
        XCTAssertEqual(snapshot.calls.count, 3)
        XCTAssertEqual(snapshot.connectedCount, 2)
        XCTAssertEqual(snapshot.heldCount, 1)
        XCTAssertEqual(snapshot.ringingCount, 1)
        XCTAssertEqual(snapshot.matchingCount(for: .connectedNotHeld), 1)
    }

    func testEndingCallbackOverridesStaleEntryInObserverList() {
        let stale = ObservedCall(id: first, hasConnected: true)
        let end = ObservedCall(id: first, hasConnected: true, hasEnded: true)
        let snapshot = CallSnapshot(calls: [stale], changed: end)
        XCTAssertFalse(snapshot.matches(.connected))
    }

    func testNewCallbackCanAddAnEntryNotYetInObserverList() {
        let call = ObservedCall(id: first, hasConnected: true)
        XCTAssertTrue(CallSnapshot(calls: [], changed: call).matches(.connected))
    }

    func testRepeatedUUIDIsNotDoubleCounted() {
        let old = ObservedCall(id: first)
        let new = ObservedCall(id: first, hasConnected: true)
        let snapshot = CallSnapshot(calls: [old, new])
        XCTAssertEqual(snapshot.calls.count, 1)
        XCTAssertEqual(snapshot.connectedCount, 1)
    }

    func testObservedTimeIsPreserved() {
        let time = Date(timeIntervalSince1970: 123)
        XCTAssertEqual(CallSnapshot(calls: [], observedAt: time).observedAt, time)
    }
}
