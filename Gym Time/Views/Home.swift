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
                // Obtain the engine instance for this timer.
                let engine = ActiveTimerEngines.shared.engine(for: timer)
                RowView(timer: timer, engine: engine)
            }
            .onDelete(perform: deleteTimers)
        }
        .navigationTitle("Timers")
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
}

struct RowView: View {
    let timer: IntervalTimer
    @ObservedObject var engine: TimerEngine
    
    var body: some View {
        NavigationLink(destination: TimerView(engine: engine)) {
            HStack {
                VStack(alignment: .leading) {
                    Text(timer.name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("\(timer.totalRounds == 0 ? "∞" : "\(timer.totalRounds)") x \(formatTime(from: timer.activeDuration)) | \(formatTime(from: timer.restDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if engine.isRunning {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 4)
        }
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
