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
                // Retrieve the engine and pass it into the row view.
                let engine = ActiveTimerEngines.shared.engine(for: timer)
                RowView(timer: timer, engine: engine)
            }
        }
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
