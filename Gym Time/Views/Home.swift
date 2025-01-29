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
    
    private func formatTime(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secondsPart = seconds % 60
        return String(format: "%d:%02d", minutes, secondsPart)
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
