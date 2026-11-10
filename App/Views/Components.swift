import SwiftUI

enum Palette {
    static let background = Color(red: 0.035, green: 0.055, blue: 0.09)
    static let surface = Color(red: 0.075, green: 0.10, blue: 0.15)
    static let mint = Color(red: 0.40, green: 0.91, blue: 0.73)
}

struct Surface<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.06)))
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased()).font(.caption.weight(.semibold))
            .tracking(1.6).foregroundStyle(.secondary)
    }
}

struct Metric: View {
    let value: Int
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value, format: .number).font(.title.weight(.semibold)).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { StatusView() }
                .tabItem { Label("Status", systemImage: "waveform.path") }
            NavigationStack { ActivityView() }
                .tabItem { Label("Activity", systemImage: "clock") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
    }
}
