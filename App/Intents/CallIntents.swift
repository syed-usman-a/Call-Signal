import AppIntents
import Foundation

enum CallCriterion: String, AppEnum {
    case appSetting, connected, connectedNotHeld, anyActive
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Call definition")
    static var caseDisplayRepresentations: [CallCriterion: DisplayRepresentation] = [
        .appSetting: "Use app setting",
        .connected: "Connected, including hold",
        .connectedNotHeld: "Connected, excluding hold",
        .anyActive: "Ringing, dialing, or connected"
    ]

    @MainActor var rule: DetectionRule {
        switch self {
        case .appSetting: return CallMonitor.shared.preferences.rule
        case .connected: return .connected
        case .connectedNotHeld: return .connectedNotHeld
        case .anyActive: return .anyActive
        }
    }
}

struct IsOnACallIntent: AppIntent {
    static var title: LocalizedStringResource = "Is On a Call"
    static var description = IntentDescription("Checks the current CallKit report and returns true or false. This action checks once; it is not a call-start automation trigger.")
    static var openAppWhenRun = false

    @Parameter(title: "Count as a call", default: .appSetting)
    var criterion: CallCriterion

    static var parameterSummary: some ParameterSummary {
        Summary("Check if on a call using \(\.$criterion)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let snapshot = try await CallReader.shared.query()
        return .result(value: snapshot.matches(criterion.rule))
    }
}

struct GetCallStateIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Call State"
    static var description = IntentDescription("Returns a readable summary: On a call, Call on hold, Incoming call, Dialing, or No calls observed.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let snapshot = try await CallReader.shared.query()
        return .result(value: snapshot.title)
    }
}

struct GetCallDetailsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Call Details JSON"
    static var description = IntentDescription("Returns current call counts and the observation time as JSON. Includes no caller names, numbers, or call identifiers.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let snapshot = try await CallReader.shared.query()
        let result = CallDetails(snapshot: snapshot, rule: CallMonitor.shared.preferences.rule)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(result)
        return .result(value: String(decoding: data, as: UTF8.self))
    }
}

private struct CallDetails: Encodable {
    let schemaVersion = 1
    let observedAt: String
    let source = "CallKit"
    let state: String
    let definition: String
    let matches: Bool
    let activeCalls: Int
    let connectedCalls: Int
    let heldCalls: Int
    let ringingCalls: Int
    let dialingCalls: Int

    init(snapshot: CallSnapshot, rule: DetectionRule) {
        observedAt = ISO8601DateFormatter().string(from: snapshot.observedAt)
        state = snapshot.title
        definition = rule.rawValue
        matches = snapshot.matches(rule)
        activeCalls = snapshot.calls.count
        connectedCalls = snapshot.connectedCount
        heldCalls = snapshot.heldCount
        ringingCalls = snapshot.ringingCount
        dialingCalls = snapshot.dialingCount
    }
}

struct SetLiveMonitoringIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Live Monitoring"
    static var description = IntentDescription("Opens CallSignal and selects live or on-demand mode. Live monitoring pauses when the app enters the background.")
    // Kept for iOS 17 / Xcode 16 compatibility. No App Intents extension is used.
    static var openAppWhenRun = true

    @Parameter(title: "Live monitoring", default: true) var enabled: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Set live monitoring to \(\.$enabled)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        CallMonitor.shared.preferences.mode = enabled ? .live : .onDemand
        let dialog: IntentDialog = enabled
            ? "Live monitoring is selected. Keep CallSignal open to observe changes."
            : "On-demand mode is selected. Check call status whenever you need it."
        return .result(dialog: dialog)
    }
}

struct CallSignalShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: IsOnACallIntent(),
                    phrases: ["Check my call with \(.applicationName)"],
                    shortTitle: "Check Call", systemImageName: "phone")
        AppShortcut(intent: GetCallStateIntent(),
                    phrases: ["Get call state with \(.applicationName)"],
                    shortTitle: "Call State", systemImageName: "waveform")
        AppShortcut(intent: SetLiveMonitoringIntent(),
                    phrases: ["Monitor calls with \(.applicationName)"],
                    shortTitle: "Live Monitoring", systemImageName: "dot.radiowaves.left.and.right")
    }
}
