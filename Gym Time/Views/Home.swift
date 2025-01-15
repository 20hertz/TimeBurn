//
//  HomeView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider
    
    var body: some View {
        List {
            ForEach(timerManager.timers) { timer in
                NavigationLink(destination: TimerView(engine: ActiveTimerEngines.shared.engine(for: timer))) {
                    VStack(alignment: .leading) {
                        Text(timer.name)
                            .font(.headline)
                        // Display the configuration as: "3 x 1:00 | 0:30"
                        // Here, we assume totalRounds == 0 means “∞” (infinite rounds)
                        let roundsText = timer.totalRounds == 0 ? "∞" : "\(timer.totalRounds)"
                        Text("\(roundsText) x \(format(seconds: timer.activeDuration)) | \(format(seconds: timer.restDuration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteTimers)
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Interval Timers")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    CreateView()
                } label: {
                    Image(systemName: "plus")
                }
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

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    let previewManager = TimerManager.shared
    previewManager.setTimers([
        IntervalTimer(name: "HIIT", activeDuration: 60, restDuration: 30, totalRounds: 5),
        IntervalTimer(name: "Tabata", activeDuration: 20, restDuration: 10, totalRounds: 8)
    ])
    return NavigationStack {
        HomeView()
            .environmentObject(previewManager)
    }
}
