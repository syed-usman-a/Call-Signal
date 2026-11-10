import CallKit
import Combine
import Foundation

struct ActivityEntry: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let title: String
    let detail: String
    let symbol: String
}

@MainActor
final class CallMonitor: NSObject, ObservableObject, CXCallObserverDelegate {
    static let shared = CallMonitor()
    static let preferencesKey = "monitorPreferences.v1"

    @Published private(set) var snapshot: CallSnapshot?
    @Published private(set) var activity: [ActivityEntry] = []
    @Published private(set) var isVisible = false
    @Published private(set) var isChecking = false
    @Published var errorMessage: String?
    @Published var preferences: MonitorPreferences {
        didSet {
            if let data = try? JSONEncoder().encode(preferences) {
                UserDefaults.standard.set(data, forKey: Self.preferencesKey)
            }
            if oldValue.rule != preferences.rule || oldValue.mode != preferences.mode {
                session.reset()
                if isVisible { establishBaseline() }
                addActivity("Detection updated", detail: "\(preferences.mode.title) · \(preferences.rule.title)", symbol: "slider.horizontal.3")
            }
        }
    }

    private let reader = CallReader.shared
    private var session = DetectionSession()

    private override init() {
        if let data = UserDefaults.standard.data(forKey: Self.preferencesKey),
           let saved = try? JSONDecoder().decode(MonitorPreferences.self, from: data) {
            preferences = saved
        } else { preferences = MonitorPreferences() }
        super.init()
    }

    var isMonitoring: Bool { isVisible && preferences.mode == .live && !Self.isSimulator }

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // Only .background pauses coverage. An incoming-call overlay can briefly
    // make the scene inactive while the process is still in the foreground.
    func resume() {
        guard !isVisible else { return }
        isVisible = true
        reader.observer.setDelegate(self, queue: .main)
        establishBaseline()
        if preferences.mode == .live {
            addActivity("Monitoring resumed", detail: "Current calls established a new baseline. Background events were not reconstructed.", symbol: "play.circle")
        }
    }

    func pause() {
        guard isVisible else { return }
        isVisible = false
        reader.observer.setDelegate(nil, queue: nil)
        session.reset()
        if preferences.mode == .live {
            addActivity("Monitoring paused", detail: "CallSignal entered the background. Open it to resume.", symbol: "pause.circle")
        }
    }

    private func establishBaseline() {
        guard !Self.isSimulator else { return }
        let current = reader.snapshot()
        snapshot = current
        session.synchronize(current, rule: preferences.rule)
    }

    func checkNow() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        do {
            let current = try await reader.query()
            snapshot = current
            // A manual check is a baseline, not evidence of a transition.
            session.synchronize(current, rule: preferences.rule)
            addActivity("Status checked", detail: current.title, symbol: "checkmark.circle")
        } catch is CancellationError {
            return
        } catch { errorMessage = error.localizedDescription }
    }

    nonisolated func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        // CallKit is configured to invoke this delegate on the main queue.
        // Copy its objects so the rest of the app only uses value snapshots.
        let update = CallSnapshot(calls: callObserver.calls.map(ObservedCall.init),
                                  changed: ObservedCall(call))
        MainActor.assumeIsolated {
            receive(update)
        }
    }

    private func receive(_ current: CallSnapshot) {
        guard isMonitoring else { return }
        snapshot = current
        if let transition = session.consume(current, rule: preferences.rule) {
            let rule = preferences.rule
            addActivity(transition.title, detail: "\(current.title) · \(rule.title)",
                        symbol: transition == .began ? "phone.fill" : "phone.down.fill")
            let shouldNotify = transition == .began ? preferences.notifyBegan : preferences.notifyEnded
            if shouldNotify {
                Task { await NotificationService.shared.post(transition, rule: rule) }
            }
        }
    }

    func clearActivity() { activity.removeAll() }

    private func addActivity(_ title: String, detail: String, symbol: String) {
        activity.insert(ActivityEntry(date: Date(), title: title, detail: detail, symbol: symbol), at: 0)
        if activity.count > 100 { activity.removeLast(activity.count - 100) }
    }

    var activityExport: String {
        let formatter = ISO8601DateFormatter()
        return (["CallSignal activity — this app session only", "Times are observations, not carrier call records."] +
            activity.reversed().map { "\(formatter.string(from: $0.date)) | \($0.title) | \($0.detail)" })
            .joined(separator: "\n")
    }
}
