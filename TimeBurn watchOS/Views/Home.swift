//
//  HomeView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator

    @State private var navigateToSelectedTimer = false
    
    var body: some View {
        Group {
            if timerManager.timers.isEmpty {
                // Placeholder view when there are no timers.
                VStack(spacing: 8) {
                    Text("No timers created yet.")
                        .font(.headline)
                    Text("Create a new timer on your iOS device.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(timerManager.timers) { timer in
                        // Retrieve the engine instance for this timer.
                        let engine = ActiveTimerEngines.shared.engine(for: timer)
                        RowView(timer: timer, engine: engine)
                    }
                }
            }
        }
        .navigationTitle("Timers")
        .navigationDestination(isPresented: $navigateToSelectedTimer) {
            if let uuid = navigationCoordinator.selectedTimerID,
               let timer = timerManager.timers.first(where: { $0.id == uuid }) {
                let engine = ActiveTimerEngines.shared.engine(for: timer)
                WatchTimerView(engine: engine)
            } else {
                Text("Timer not found.")
            }
        }
        .onChange(of: navigationCoordinator.selectedTimerID) { oldValue, newValue in
            navigateToSelectedTimer = (newValue != nil)
        }
    }
}

struct RowView: View {
    let timer: IntervalTimer
    @ObservedObject var engine: TimerEngine

    var body: some View {
        NavigationLink(destination: WatchTimerView(engine: engine)) {
            HStack {
                VStack(alignment: .leading) {
                    if timer.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // No name provided – show the configuration string as headline.
                        Text("\(timer.totalRounds == 0 ? "∞" : "\(timer.totalRounds)") x \(formatTime(from: timer.activeDuration)) | \(formatTime(from: timer.restDuration))")
                            .font(.headline)
                    } else {
                        Text(timer.name)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text("\(timer.totalRounds == 0 ? "∞" : "\(timer.totalRounds)") x \(formatTime(from: timer.activeDuration)) | \(formatTime(from: timer.restDuration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if engine.isRunning {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    let previewManager = TimerManager.shared
    // Uncomment one of these to test empty state versus list state:
    // previewManager.setTimers([])  // Empty state – shows placeholder message.
    previewManager.setTimers([
        IntervalTimer(name: "Circuit", activeDuration: 45, restDuration: 15, totalRounds: 6),
        IntervalTimer(name: "Sprint", activeDuration: 30, restDuration: 30, totalRounds: 5)
    ])
    
    return NavigationView {
        WatchHomeView()
            .environmentObject(previewManager)
    }
}
