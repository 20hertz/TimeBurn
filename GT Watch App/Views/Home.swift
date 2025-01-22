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

struct RowView: View {
    let timer: IntervalTimer
    @ObservedObject var engine: TimerEngine

    var body: some View {
        NavigationLink(destination: WatchTimerView(engine: engine)) {
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
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 4)
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
