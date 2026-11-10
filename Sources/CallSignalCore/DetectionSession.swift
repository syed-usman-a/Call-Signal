import Foundation

public enum MatchTransition: String, Codable, Sendable {
    case began, ended
    public var title: String { self == .began ? "Call condition became true" : "Call condition became false" }
}

/// Tracks the aggregate condition, not individual call endings. Changing a rule,
/// pausing, and resuming establish a fresh baseline and never invent events.
public struct DetectionSession: Sendable {
    private var previousMatch: Bool?
    private var previousRule: DetectionRule?

    public init() {}

    public mutating func reset() {
        previousMatch = nil
        previousRule = nil
    }

    public mutating func synchronize(_ snapshot: CallSnapshot, rule: DetectionRule) {
        previousMatch = snapshot.matches(rule)
        previousRule = rule
    }

    public mutating func consume(_ snapshot: CallSnapshot, rule: DetectionRule) -> MatchTransition? {
        let matches = snapshot.matches(rule)
        defer {
            previousMatch = matches
            previousRule = rule
        }
        guard previousRule == rule, let previousMatch, previousMatch != matches else { return nil }
        return matches ? .began : .ended
    }
}

public enum MonitoringMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case onDemand, live
    public var id: String { rawValue }
    public var title: String { self == .onDemand ? "On demand" : "Live monitor" }
}

public struct MonitorPreferences: Codable, Equatable, Sendable {
    public var mode: MonitoringMode = .onDemand
    public var rule: DetectionRule = .connected
    public var notifyBegan = false
    public var notifyEnded = false

    public init() {}
}
