import XCTest
@testable import CallSignalCore

final class DetectionSessionTests: XCTestCase {
    private let first = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let second = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private var idle: CallSnapshot { CallSnapshot(calls: []) }
    private var connected: CallSnapshot { CallSnapshot(calls: [ObservedCall(id: first, hasConnected: true)]) }

    func testInitialActiveObservationIsBaselineNotCallStarted() {
        var session = DetectionSession()
        XCTAssertNil(session.consume(connected, rule: .connected))
    }

    func testIdleToConnectedEmitsExactlyOneStart() {
        var session = DetectionSession()
        session.synchronize(idle, rule: .connected)
        XCTAssertEqual(session.consume(connected, rule: .connected), .began)
        XCTAssertNil(session.consume(connected, rule: .connected))
    }

    func testLastCallEndingEmitsExactlyOneEnd() {
        var session = DetectionSession()
        session.synchronize(connected, rule: .connected)
        XCTAssertEqual(session.consume(idle, rule: .connected), .ended)
        XCTAssertNil(session.consume(idle, rule: .connected))
    }

    func testEndingOneOfTwoCallsDoesNotEndAggregateCondition() {
        var session = DetectionSession()
        session.synchronize(CallSnapshot(calls: [
            ObservedCall(id: first, hasConnected: true),
            ObservedCall(id: second, hasConnected: true)
        ]), rule: .connected)
        XCTAssertNil(session.consume(connected, rule: .connected))
        XCTAssertEqual(session.consume(idle, rule: .connected), .ended)
    }

    func testCallWaitingDoesNotInterruptExistingConnectedCondition() {
        var session = DetectionSession()
        session.synchronize(connected, rule: .connected)
        let waiting = CallSnapshot(calls: [ObservedCall(id: first, hasConnected: true), ObservedCall(id: second)])
        XCTAssertNil(session.consume(waiting, rule: .connected))
        XCTAssertNil(session.consume(connected, rule: .connected))
    }

    func testUnansweredRingDoesNotProduceConnectedTransitions() {
        var session = DetectionSession()
        session.synchronize(idle, rule: .connected)
        XCTAssertNil(session.consume(CallSnapshot(calls: [ObservedCall(id: first)]), rule: .connected))
        XCTAssertNil(session.consume(idle, rule: .connected))
    }

    func testRingingCanTriggerAnyActiveDefinition() {
        var session = DetectionSession()
        session.synchronize(idle, rule: .anyActive)
        XCTAssertEqual(session.consume(CallSnapshot(calls: [ObservedCall(id: first)]), rule: .anyActive), .began)
        XCTAssertNil(session.consume(connected, rule: .anyActive))
        XCTAssertEqual(session.consume(idle, rule: .anyActive), .ended)
    }

    func testHoldAndResumeAffectOnlyExcludingHoldDefinition() {
        let held = CallSnapshot(calls: [ObservedCall(id: first, hasConnected: true, isOnHold: true)])
        var inclusive = DetectionSession()
        inclusive.synchronize(connected, rule: .connected)
        XCTAssertNil(inclusive.consume(held, rule: .connected))
        var exclusive = DetectionSession()
        exclusive.synchronize(connected, rule: .connectedNotHeld)
        XCTAssertEqual(exclusive.consume(held, rule: .connectedNotHeld), .ended)
        XCTAssertEqual(exclusive.consume(connected, rule: .connectedNotHeld), .began)
    }

    func testChangingDefinitionDoesNotInventTransition() {
        var session = DetectionSession()
        let ringing = CallSnapshot(calls: [ObservedCall(id: first)])
        session.synchronize(ringing, rule: .connected)
        XCTAssertNil(session.consume(ringing, rule: .anyActive))
        XCTAssertEqual(session.consume(idle, rule: .anyActive), .ended)
    }

    func testResumeDoesNotReconstructMissedEvents() {
        var session = DetectionSession()
        session.synchronize(idle, rule: .connected)
        session.reset()
        session.synchronize(connected, rule: .connected)
        XCTAssertNil(session.consume(connected, rule: .connected))
        XCTAssertEqual(session.consume(idle, rule: .connected), .ended)
    }

    func testPreferenceDefaultsAreOnDemandWithoutNotifications() throws {
        let defaults = MonitorPreferences()
        XCTAssertEqual(defaults.mode, .onDemand)
        XCTAssertEqual(defaults.rule, .connected)
        XCTAssertFalse(defaults.notifyBegan)
        XCTAssertFalse(defaults.notifyEnded)
        let roundTrip = try JSONDecoder().decode(MonitorPreferences.self, from: JSONEncoder().encode(defaults))
        XCTAssertEqual(defaults, roundTrip)
    }
}
