//
//  TimerView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-13.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider
    @ObservedObject var engine: TimerEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Countdown display
            Text(timeString(from: engine.remainingTime))
                .font(.system(size: 60, design: .monospaced))
                .padding(.top, 40)
            
            if engine.timer.totalRounds != 0 {
                Text(roundIndicator)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Left: Back button (chevron)
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
            }
            // Center: Timer name
            ToolbarItem(placement: .principal) {
                Text(engine.timer.name)
                    .font(.headline)
            }
            // Right: Edit button (cog icon) which navigates to an Edit view (not implemented here).
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    EditView(timer: engine.timer)
                } label: {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                }
            }
            // Bottom Toolbar with Reset and Primary Action buttons.
            ToolbarItemGroup(placement: .bottomBar) {
                if engine.phase != .idle {
                    Button {
                        engine.reset()
                        sendAction(.reset)
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                Spacer()
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
                        .font(.system(size: 40))
                }
                Spacer()
            }
        }
    }
    
    private var roundIndicator: String {
        let total = engine.timer.totalRounds
        // If totalRounds == 0, we treat it as indefinite.
        if total == 0 {
            return "Round: \(engine.currentRound) / ∞"
        } else {
            return "Round: \(engine.currentRound) / \(total)"
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func sendAction(_ action: TimerAction) {
        connectivityProvider.sendAction(timerID: engine.timer.id, action: action)
    }
}

#Preview {
    let sampleTimer = IntervalTimer(name: "Interval Timer", activeDuration: 60, restDuration: 30, totalRounds: 5)
    let engine = TimerEngine(timer: sampleTimer)
    return NavigationView {
        TimerView(engine: engine)
    }
}
