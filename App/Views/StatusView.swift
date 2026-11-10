import SwiftUI

struct StatusView: View {
    @EnvironmentObject private var monitor: CallMonitor

    private var statusSymbol: String {
        guard let snapshot = monitor.snapshot else { return "phone" }
        if snapshot.heldCount > 0 && snapshot.heldCount == snapshot.connectedCount { return "pause.fill" }
        if snapshot.connectedCount > 0 { return "phone.fill" }
        if snapshot.ringingCount > 0 { return "phone.arrow.down.left.fill" }
        if snapshot.dialingCount > 0 { return "phone.arrow.up.right.fill" }
        return "phone"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Eyebrow(text: "A little more awareness")
                    Spacer()
                    Image(systemName: "iphone.gen3").foregroundStyle(Palette.mint).accessibilityHidden(true)
                }

                Surface {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 8) {
                            Circle().fill(monitor.isMonitoring ? Palette.mint : Color.secondary)
                                .frame(width: 7, height: 7).accessibilityHidden(true)
                            Text(CallMonitor.isSimulator ? "Physical iPhone required" :
                                 monitor.isMonitoring ? "Monitoring while open" : "Check when you need it")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }

                        HStack {
                            Spacer()
                            ZStack {
                                Circle().stroke(Palette.mint.opacity(0.08), lineWidth: 1).frame(width: 164, height: 164)
                                Circle().stroke(Palette.mint.opacity(0.16), lineWidth: 1).frame(width: 130, height: 130)
                                Circle().fill(Palette.mint.opacity(0.09)).frame(width: 96, height: 96)
                                Image(systemName: statusSymbol).font(.system(size: 35, weight: .medium))
                                    .foregroundStyle(Palette.mint)
                            }.accessibilityHidden(true)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text(monitor.snapshot?.title ?? "Ready to check")
                                .font(.largeTitle.weight(.semibold)).fontDesign(.rounded)
                                .fixedSize(horizontal: false, vertical: true)
                            if let snapshot = monitor.snapshot {
                                Text(snapshot.matches(monitor.preferences.rule) ? "Your call condition is true." : "Your call condition is false.")
                                    .foregroundStyle(.secondary)
                                Text("Observed \(snapshot.observedAt.formatted(date: .omitted, time: .standard))")
                                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                            } else {
                                Text("See the call state reported by your iPhone.").foregroundStyle(.secondary)
                            }
                        }

                        Divider()
                        HStack {
                            Metric(value: monitor.snapshot?.calls.count ?? 0, title: "Total calls")
                            Metric(value: monitor.snapshot?.connectedCount ?? 0, title: "Connected")
                            Metric(value: monitor.snapshot?.heldCount ?? 0, title: "On hold")
                        }
                        if monitor.snapshot == nil {
                            Text("Counts have not been checked yet.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "Choose how to check")
                    Picker("Detection mode", selection: $monitor.preferences.mode) {
                        ForEach(MonitoringMode.allCases) { mode in Text(mode.title).tag(mode) }
                    }.pickerStyle(.segmented)
                    Text(monitor.preferences.mode == .live
                         ? "Watches for changes while CallSignal is open. Monitoring pauses when you switch apps or lock your phone."
                         : "Check with the button below or use CallSignal in a shortcut. Each check returns the current reported state.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Task { await monitor.checkNow() }
                } label: {
                    HStack {
                        Spacer()
                        if monitor.isChecking { ProgressView().tint(Palette.background) }
                        else { Image(systemName: "arrow.clockwise") }
                        Text(monitor.isChecking ? "Checking…" : "Check now").fontWeight(.semibold)
                        Spacer()
                    }.padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent).foregroundStyle(Palette.background)
                .controlSize(.large).disabled(monitor.isChecking || CallMonitor.isSimulator)

                Surface {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Your definition", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.headline)
                        Text(monitor.preferences.rule.title).foregroundStyle(Palette.mint)
                        Text(monitor.preferences.rule.explanation).font(.subheadline).foregroundStyle(.secondary)
                    }
                }

                NavigationLink(destination: ShortcutsGuideView()) {
                    HStack {
                        Image(systemName: "square.stack.3d.up").foregroundStyle(Palette.mint)
                        Text("Use it in Shortcuts").foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }.padding(.vertical, 8)
                }

                if CallMonitor.isSimulator {
                    Text("The simulator can display the app, but cannot verify phone calls. Run on your iPhone to test detection.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Text("Call state only. No microphone access, recordings, or caller details.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(20)
        }
        .background(Palette.background)
        .navigationTitle("CallSignal")
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            NavigationLink(destination: AboutView()) {
                Image(systemName: "info.circle").accessibilityLabel("About call detection")
            }
        } }
        .alert("Couldn’t check call status", isPresented: Binding(
            get: { monitor.errorMessage != nil },
            set: { if !$0 { monitor.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { monitor.errorMessage = nil }
        } message: { Text(monitor.errorMessage ?? "") }
    }
}
