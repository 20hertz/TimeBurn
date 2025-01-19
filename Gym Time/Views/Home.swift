//
//  HomeView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        List {
            ForEach(timerManager.timers) { timer in
                // Obtain the engine instance for this timer.
                let engine = ActiveTimerEngines.shared.engine(for: timer)
                RowView(timer: timer, engine: engine)
            }
        }
        .navigationTitle("Timers")
    }
}

#Preview {
    let sampleTimer = IntervalTimer(name: "HIIT", activeDuration: 60, restDuration: 30, totalRounds: 5)
    
    let previewManager = TimerManager.shared
    
    previewManager.setTimers([
        sampleTimer,
        IntervalTimer(name: "Tabata", activeDuration: 20, restDuration: 10, totalRounds: 8)
    ])
    
    let engine = TimerEngine(timer: sampleTimer)
    // For testing, simulate a running state for this timer:
    engine.isRunning = true
    
    return NavigationStack {
        HomeView()
            .environmentObject(previewManager)
    }
}
