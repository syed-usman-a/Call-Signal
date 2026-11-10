import CallKit
import Foundation

extension ObservedCall {
    init(_ call: CXCall) {
        self.init(id: call.uuid, isOutgoing: call.isOutgoing,
                  hasConnected: call.hasConnected, hasEnded: call.hasEnded,
                  isOnHold: call.isOnHold)
    }
}

@MainActor
final class CallReader {
    static let shared = CallReader()
    // Retain the observer for the lifetime of the process.
    let observer = CXCallObserver()

    private init() {}

    func snapshot() -> CallSnapshot {
        CallSnapshot(calls: observer.calls.map(ObservedCall.init))
    }

    func query() async throws -> CallSnapshot {
        #if targetEnvironment(simulator)
        throw CallReadError.simulator
        #else
        try Task.checkCancellation()
        // Yield once so a newly launched process can service pending work.
        // This is not a guarantee that every VoIP provider reports every call.
        await Task.yield()
        try Task.checkCancellation()
        return snapshot()
        #endif
    }
}

enum CallReadError: LocalizedError {
    case simulator
    var errorDescription: String? {
        "Call detection requires a physical iPhone. The simulator cannot verify real calls."
    }
}
