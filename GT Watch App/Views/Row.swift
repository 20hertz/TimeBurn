//
//  WatchTimerRowView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-18.
//


import SwiftUI

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
                if engine.phase != .idle && engine.phase != .completed {
                    Circle()
                        .fill(engine.isRunning ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let sampleTimer = IntervalTimer(name: "Interval Timer", activeDuration: 60, restDuration: 30, totalRounds: 5)
    let engine = TimerEngine(timer: sampleTimer)
    // Uncomment one of these to test running states:
    // engine.isRunning = true  // Running state (dot will be green)
    // engine.isRunning = false // Paused state (dot will be red)
    return NavigationView {
        RowView(timer: sampleTimer, engine: engine)
    }
}
