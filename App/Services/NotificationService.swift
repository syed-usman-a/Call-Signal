import UserNotifications
import Foundation
import Combine

@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    @Published private(set) var status: UNAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    var isAuthorized: Bool { status == .authorized || status == .provisional || status == .ephemeral }

    var statusText: String {
        switch status {
        case .authorized, .ephemeral: return "Allowed"
        case .provisional: return "Delivered quietly"
        case .denied: return "Off in iPhone Settings"
        case .notDetermined: return "Not enabled"
        @unknown default: return "Unknown"
        }
    }

    func refreshAuthorization() async {
        status = await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            await refreshAuthorization()
        } catch { errorMessage = error.localizedDescription }
    }

    func post(_ transition: MatchTransition, rule: DetectionRule) async {
        await refreshAuthorization()
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = transition.title
        content.body = "CallSignal observed a change. Detection: \(rule.title)."
        content.sound = .default
        do {
            try await center.add(UNNotificationRequest(identifier: UUID().uuidString,
                                                       content: content, trigger: nil))
        } catch { errorMessage = error.localizedDescription }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
