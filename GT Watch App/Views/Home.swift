//
//  HomeView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var timerManager: TimerManager

    var body: some View {
        List {
            ForEach(timerManager.timers) { timer in
                NavigationLink(destination: WatchTimerView(engine: ActiveTimerEngines.shared.engine(for: timer))) {
                    VStack(alignment: .leading) {
                        Text(timer.name)
                            .font(.headline)
                        Text("\(timer.totalRounds == 0 ? "∞" : "\(timer.totalRounds)") x \(format(seconds: timer.activeDuration)) | \(format(seconds: timer.restDuration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Timers")
    }

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let secondsPart = seconds % 60
        return String(format: "%d:%02d", minutes, secondsPart)
    }
}

#Preview {
    let previewManager = TimerManager.shared
    previewManager.setTimers([
        IntervalTimer(name: "Circuit", activeDuration: 45, restDuration: 15, totalRounds: 6),
        IntervalTimer(name: "Sprint", activeDuration: 30, restDuration: 30, totalRounds: 5)
    ])
    return NavigationView {
        WatchHomeView()
            .environmentObject(previewManager)
    }
}
