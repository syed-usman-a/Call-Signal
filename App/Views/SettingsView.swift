import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var monitor: CallMonitor
    @EnvironmentObject private var notifications: NotificationService

    var body: some View {
        Form {
            Section {
                Picker("Count as a call", selection: $monitor.preferences.rule) {
                    ForEach(DetectionRule.allCases) { rule in Text(rule.title).tag(rule) }
                }.pickerStyle(.navigationLink)
            } header: { Text("Detection") } footer: {
                Text("\(monitor.preferences.rule.explanation) Shortcuts can use this setting or choose their own definition.")
            }

            Section {
                LabeledContent("Permission", value: notifications.statusText)
                if notifications.status == .notDetermined {
                    Button("Allow notifications") { Task { await notifications.requestAuthorization() } }
                } else if notifications.status == .denied {
                    Button("Open iPhone Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                }
                Toggle("When the condition becomes true", isOn: $monitor.preferences.notifyBegan)
                    .disabled(!notifications.isAuthorized)
                Toggle("When the condition becomes false", isOn: $monitor.preferences.notifyEnded)
                    .disabled(!notifications.isAuthorized)
            } header: { Text("Live notifications") } footer: {
                Text("Applies in Live monitor mode while the app is open. With “Connected, excluding hold,” putting your last connected call on hold makes the condition false. Returning to the app establishes a new baseline without sending a notification.")
            }

            Section {
                NavigationLink("Set up a shortcut", destination: ShortcutsGuideView())
                NavigationLink("How detection works", destination: AboutView())
            } header: { Text("Learn") }

            Section {
                Label("Everything stays on your device", systemImage: "iphone.gen3")
                Text("Only your settings are saved. The activity log is held in memory, clears when the app process ends, and is shared only if you choose Export. CallSignal has no analytics, server, microphone access, or caller-number access.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } header: { Text("Privacy") }

            Section {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Source license", value: "MIT")
            }
        }
        .scrollContentBackground(.hidden).background(Palette.background)
        .navigationTitle("Settings")
        .task { await notifications.refreshAuthorization() }
        .alert("Notification issue", isPresented: Binding(
            get: { notifications.errorMessage != nil },
            set: { if !$0 { notifications.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { notifications.errorMessage = nil }
        } message: { Text(notifications.errorMessage ?? "") }
    }
}

struct ShortcutsGuideView: View {
    var body: some View {
        List {
            Section("Build your first shortcut") {
                GuideStep(number: "1", title: "Add the action", detail: "Open Shortcuts, create a shortcut, and search for CallSignal. Add “Is On a Call.”")
                GuideStep(number: "2", title: "Choose a definition", detail: "Use the app setting, or choose whether ringing, dialing, and held calls count.")
                GuideStep(number: "3", title: "Add an If", detail: "Use the Boolean output from “Is On a Call” as the condition. Put your actions in the true and Otherwise branches.")
                GuideStep(number: "4", title: "Run it", detail: "Run manually, from a widget, the Action button, or another supported Shortcuts automation trigger.")
            }
            Section("Available actions") {
                GuideStep(number: "•", title: "Is On a Call", detail: "A true or false result for your selected definition.")
                GuideStep(number: "•", title: "Get Call State", detail: "A readable description of the current reported call state.")
                GuideStep(number: "•", title: "Get Call Details JSON", detail: "Counts and an observation time for advanced shortcuts. Use Get Dictionary from Input to read the JSON.")
                GuideStep(number: "•", title: "Set Live Monitoring", detail: "Opens CallSignal and chooses live or on-demand mode.")
            }
            Section("Checks and triggers") {
                Text("The actions run when something invokes them. They do not add a “call started” trigger to Shortcuts. Live monitor observes changes inside CallSignal while it is open.")
                Text("If the actions do not appear, open CallSignal once and relaunch Shortcuts. Test on a real iPhone.")
            }
        }
        .navigationTitle("Shortcuts").navigationBarTitleDisplayMode(.inline)
    }
}

private struct GuideStep: View {
    let number: String
    let title: String
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.headline).foregroundStyle(Palette.mint).frame(width: 22)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 7)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section("What CallSignal sees") {
                Text("CallSignal reads the active-call information exposed by Apple’s CallKit. Cellular calls and compatible app calls can appear here. Coverage depends on the calling app, device, region, and iOS version; verify the services you use.")
                Text("“No calls observed” means CallKit reported no active calls at that check. It is not a guarantee that every possible calling app is idle.")
            }
            Section("Two ways to use it") {
                Text("On demand: inspect the current report from the app or Shortcuts.")
                Text("Live monitor: observe changes while CallSignal is open. Brief incoming-call overlays may make the scene inactive without putting it in the background.")
            }
            Section("When you leave the app") {
                Text("Monitoring pauses when CallSignal enters the background, including normal app switching or locking. Opening it again reads the current state and starts a new baseline. Calls that started and ended while it was paused cannot be recovered.")
                Text("There is no always-on background mode in this app. iOS does not grant a general-purpose app unlimited execution to watch other apps’ calls.")
            }
            Section("What it does not access") {
                Text("Call audio, microphone input, contact names, phone numbers, and the Phone app’s call history are not accessed.")
            }
        }
        .navigationTitle("How it works").navigationBarTitleDisplayMode(.inline)
    }
}
