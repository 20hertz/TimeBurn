//
//  HomeView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    @State private var navigateToSelectedTimer = false
    
    var body: some View {
        Group {
            if timerManager.timers.isEmpty {
                VStack(spacing: 12) {
                    Text("The timers you create will appear here.")
                        .font(.headline)
                    Text("Hit the '+' sign up top to create one.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(timerManager.timers) { timer in
                        // Obtain the engine instance for this timer.
                        let engine = ActiveTimerEngines.shared.engine(for: timer)
                        RowView(timer: timer, engine: engine)
                    }
                    .onDelete(perform: deleteTimers)
                }
                .navigationTitle("My Timers")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    CreateView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(isPresented: $navigateToSelectedTimer) {
            if let uuid = navigationCoordinator.selectedTimerID,
               let timer = timerManager.timers.first(where: { $0.id == uuid }) {
                let engine = ActiveTimerEngines.shared.engine(for: timer)
                TimerView(engine: engine)
            } else {
                Text("Timer not found.")
            }
        }
        .onChange(of: navigationCoordinator.selectedTimerID) { newValue in
            // If we got a new timer, navigate
            if newValue != nil {
                navigateToSelectedTimer = true
            } else {
                navigateToSelectedTimer = false
            }
        }
    }
    
    private func deleteTimers(at offsets: IndexSet) {
        offsets.forEach { index in
            let timer = timerManager.timers[index]
            timerManager.deleteTimer(timer)
        }
        connectivityProvider.sendTimers(timerManager.timers)
    }
}
struct RowView: View {
    let timer: IntervalTimer
    @ObservedObject var engine: TimerEngine
    
    var body: some View {
        NavigationLink(destination: TimerView(engine: engine)) {
            HStack {
                if timer.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Timer has no name; display the configuration text aligned to the left,
                    // but still centered vertically within the fixed row height.
                    Text(configText)
                        .font(.headline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                } else {
                    // Timer has a name; display the name and the config text.
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timer.name)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(configText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if engine.isRunning {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 4)
            // Set a fixed row height so that all rows are consistent.
            .frame(height: 50)
        }
    }
    
    private var configText: String {
        "\(timer.totalRounds == 0 ? "∞" : "\(timer.totalRounds)") x \(formatTime(from: timer.activeDuration)) | \(formatTime(from: timer.restDuration))"
    }
}

#Preview {
    let sampleTimer = IntervalTimer(name: "HIIT", activeDuration: 60, restDuration: 30, totalRounds: 5)
    
    let previewManager = TimerManager.shared
    // Test with an empty list (comment out setTimers below to test empty state)
    previewManager.setTimers([
        sampleTimer,
        IntervalTimer(name: "Tabata", activeDuration: 20, restDuration: 10, totalRounds: 8)
    ])
    
    let engine = TimerEngine(timer: sampleTimer)
    engine.isRunning = true
    
    return NavigationStack {
        HomeView()
            .environmentObject(previewManager)
    }
}
