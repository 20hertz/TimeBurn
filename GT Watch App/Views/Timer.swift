//
//  TimerView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-09.
//

import SwiftUI

struct WatchTimerView: View {
    @ObservedObject var engine: TimerEngine
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider

    var body: some View {
        VStack(spacing: 12) {
            // Countdown display
            Text(timeString(from: engine.remainingTime))
                .font(.system(.title, design: .monospaced))
                .padding(.top, 20)
            
            // Round indicator
            Text(roundIndicator)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Controls: Reset (if started) and Play/Pause
            HStack(spacing: 20) {
                if engine.phase != .idle {
                    Button {
                        engine.reset()
                        sendAction(.reset)
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                
                Button {
                    if engine.isRunning {
                        engine.pause()
                        sendAction(.pause)
                    } else {
                        engine.play()
                        sendAction(.play)
                    }
                } label: {
                    Image(systemName: engine.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.largeTitle)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private var roundIndicator: String {
        let total = engine.timer.totalRounds
        if total == 0 {
            return "Round \(engine.currentRound) / ∞"
        } else {
            return "Round \(engine.currentRound) / \(total)"
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func sendAction(_ action: TimerAction) {
        connectivityProvider.sendAction(timerID: engine.timer.id, action: action)
    }
}

#Preview {
    let sampleTimer = IntervalTimer(name: "Watch Timer", activeDuration: 45, restDuration: 15, totalRounds: 4)
    let engine = TimerEngine(timer: sampleTimer)
    return WatchTimerView(engine: engine)
}
