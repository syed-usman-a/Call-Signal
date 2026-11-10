import Foundation

/// A value copy of the public CallKit flags. It contains no caller identity.
public struct ObservedCall: Equatable, Sendable {
    public let id: UUID
    public let isOutgoing: Bool
    public let hasConnected: Bool
    public let hasEnded: Bool
    public let isOnHold: Bool

    public init(id: UUID, isOutgoing: Bool = false, hasConnected: Bool = false,
                hasEnded: Bool = false, isOnHold: Bool = false) {
        self.id = id
        self.isOutgoing = isOutgoing
        self.hasConnected = hasConnected
        self.hasEnded = hasEnded
        self.isOnHold = isOnHold
    }

    public var phase: CallPhase {
        if hasEnded { return .ended }
        if hasConnected { return isOnHold ? .held : .connected }
        return isOutgoing ? .dialing : .ringing
    }
}

public enum CallPhase: String, Sendable {
    case ringing, dialing, connected, held, ended

    public var title: String {
        switch self {
        case .ringing: return "Ringing"
        case .dialing: return "Dialing"
        case .connected: return "Connected"
        case .held: return "On hold"
        case .ended: return "Ended"
        }
    }
}

public enum DetectionRule: String, Codable, CaseIterable, Identifiable, Sendable {
    case connected, connectedNotHeld, anyActive
    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .connected: return "Connected, including hold"
        case .connectedNotHeld: return "Connected, excluding hold"
        case .anyActive: return "Ringing, dialing, or connected"
        }
    }

    public var explanation: String {
        switch self {
        case .connected: return "A call counts after it connects, even while on hold."
        case .connectedNotHeld: return "A call counts after it connects, unless it is on hold."
        case .anyActive: return "A call counts as soon as it rings or starts dialing."
        }
    }

    public func matches(_ call: ObservedCall) -> Bool {
        guard !call.hasEnded else { return false }
        switch self {
        case .connected: return call.hasConnected
        case .connectedNotHeld: return call.hasConnected && !call.isOnHold
        case .anyActive: return true
        }
    }
}

public struct CallSnapshot: Equatable, Sendable {
    public let observedAt: Date
    public let calls: [ObservedCall]

    public init(calls: [ObservedCall], observedAt: Date = Date()) {
        self.observedAt = observedAt
        // Keep one entry per call and ensure ended calls never count as active.
        var unique: [UUID: ObservedCall] = [:]
        for call in calls { unique[call.id] = call }
        self.calls = unique.values.filter { !$0.hasEnded }
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    /// The callback payload is authoritative for the changed call at that event.
    /// It may be absent from `calls` when it has just ended.
    public init(calls: [ObservedCall], changed: ObservedCall, observedAt: Date = Date()) {
        self.init(calls: calls.filter { $0.id != changed.id } + [changed],
                  observedAt: observedAt)
    }

    public func matchingCount(for rule: DetectionRule) -> Int {
        calls.filter(rule.matches).count
    }

    public func matches(_ rule: DetectionRule) -> Bool { matchingCount(for: rule) > 0 }
    public var connectedCount: Int { calls.filter { $0.hasConnected }.count }
    public var heldCount: Int { calls.filter { $0.hasConnected && $0.isOnHold }.count }
    public var ringingCount: Int { calls.filter { $0.phase == .ringing }.count }
    public var dialingCount: Int { calls.filter { $0.phase == .dialing }.count }

    public var title: String {
        if connectedCount > heldCount { return "On a call" }
        if heldCount > 0 { return "Call on hold" }
        if ringingCount > 0 { return "Incoming call" }
        if dialingCount > 0 { return "Dialing" }
        return "No calls observed"
    }
}
