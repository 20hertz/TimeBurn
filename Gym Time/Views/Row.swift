//
//  HomeTimerRowView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-18.
//


import SwiftUI

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

#Preview(traits: .sizeThatFitsLayout) {
    let sampleTimer = IntervalTimer(
        name: "Demo Timer",
        activeDuration: 60,
        restDuration: 30,
        totalRounds: 5
    )
    let engine = TimerEngine(timer: sampleTimer)
    
    NavigationView {
        RowView(timer: sampleTimer, engine: engine)
    }
}
