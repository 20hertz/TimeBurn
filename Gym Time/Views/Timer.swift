//
//  TimerView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-13.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    let timer: IntervalTimer
    
    var body: some View {
        VStack {
            // Example placeholder for the countdown and round progress
            Text("Round \(timer.currentRound)/\(timer.activeRounds)")
                .font(.title)
                .padding(.top, 40)
            Text(timer.isRunning ? "Running..." : "Paused")
                .font(.headline)
                .padding(.bottom, 20)
            
            // Visual round indicators (Placeholder):
            HStack {
                ForEach(0 ..< timer.activeRounds, id: \.self) { index in
                    Circle()
                        .fill(index < timer.currentRound ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                }
            }
            
            Spacer()
        }
        .navigationTitle(timer.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Cog (edit) on the right
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    EditView(timer: timer)
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            
            // Bottom bar with reset (left) and play/pause (center)
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    if timer.hasBegun {
                        Button {
                            // Reset logic
                            timerManager.resetTimer(timer)
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // This space ensures the next button is centered
                        Spacer().frame(maxWidth: .infinity)
                    }
                    
                    Button {
                        // Toggle isRunning
                        let newVal = !timer.isRunning
                        timerManager.updateTimer(timer, isRunning: newVal)
                    } label: {
                        Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview("iOS TimerView (Running)") {
    NavigationStack {
        TimerView(timer:
                    IntervalTimer(id: UUID(), name: "Sample Timer", activeDuration: 60, restDuration: 30, totalRounds: <#Int#>)
        )
        .environmentObject(TimerManager.shared)
    }
}
