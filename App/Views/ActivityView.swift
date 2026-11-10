import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var monitor: CallMonitor
    @State private var confirmClear = false

    var body: some View {
        Group {
            if monitor.activity.isEmpty {
                ContentUnavailableView {
                    Label("A fresh start", systemImage: "clock")
                } description: {
                    Text("Checks and changes to your call condition appear here. Activity stays in memory for this app session.")
                } actions: {
                    Button("Check call status") { Task { await monitor.checkNow() } }
                        .disabled(CallMonitor.isSimulator)
                }
            } else {
                List {
                    Section {
                        ForEach(monitor.activity) { entry in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: entry.symbol).foregroundStyle(Palette.mint)
                                    .frame(width: 24).padding(.top, 3).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.title).font(.headline)
                                    Text(entry.detail).font(.subheadline).foregroundStyle(.secondary)
                                    Text(entry.date.formatted(date: .omitted, time: .standard))
                                        .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                                }
                            }.padding(.vertical, 6)
                        }
                    } footer: {
                        Text("The latest 100 observations in this app session. This is not your phone’s call history. Events while monitoring was paused are unavailable.")
                    }
                }.scrollContentBackground(.hidden)
            }
        }
        .background(Palette.background)
        .navigationTitle("Activity")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: monitor.activityExport) {
                    Image(systemName: "square.and.arrow.up").accessibilityLabel("Export session activity")
                }.disabled(monitor.activity.isEmpty)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { confirmClear = true } label: {
                    Image(systemName: "trash").accessibilityLabel("Clear session activity")
                }.disabled(monitor.activity.isEmpty)
            }
        }
        .confirmationDialog("Clear this session’s activity?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear activity", role: .destructive) { monitor.clearActivity() }
        }
    }
}
