import SwiftUI

@main
struct CallSignalApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var monitor = CallMonitor.shared
    @StateObject private var notifications = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(monitor)
                .environmentObject(notifications)
                .tint(Palette.mint)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    switch phase {
                    case .active:
                        monitor.resume()
                        Task { await notifications.refreshAuthorization() }
                    case .background: monitor.pause()
                    case .inactive: break
                    @unknown default: monitor.pause()
                    }
                }
        }
    }
}
