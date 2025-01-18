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
        VStack {
            Spacer()
            // Group timerDisplay and roundIndicator together.
            VStack(spacing: 16) {
                timerDisplay()
                roundIndicator()
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
                    Image(systemName: "gearshape")
                        .foregroundColor(.blue)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                ZStack {
                    // Left-aligned reset button.
                    HStack {
                        if engine.phase != .idle {
                            resetButton()
                        }
                        Spacer()
                    }
                    playPauseButton()
                }
            }
        }
    }
    
    // MARK: - Timer Display
    private func timerDisplay() -> some View {
        VStack(spacing: 16) {
            // Always render the "REST" label with fixed height,
            // but only make it visible when in rest phase.
            Text("REST")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black)
                .opacity(engine.phase == .rest ? 1.0 : 0.0)
                .frame(height: 30)  // Reserve the same space always.
            
            CircularProgressBar(
                progress: Double(progress),
                remainingTime: engine.remainingTime
            )
            .frame(width: 250, height: 250)
        }
        .padding(.vertical, 0)
    }
    
    // MARK: - Round Indicator
    @ViewBuilder
    private func roundIndicator() -> some View {
        if engine.timer.totalRounds > 1 {
            HStack(spacing: 8) {
                ForEach(0..<engine.timer.totalRounds, id: \.self) { index in
                    Circle()
                        .fill(index < engine.currentRound ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 20, height: 20)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private var progress: CGFloat {
        let totalDuration: CGFloat
        if engine.phase == .rest {
            totalDuration = CGFloat(engine.timer.restDuration)
        } else {
            totalDuration = CGFloat(engine.timer.activeDuration)
        }
        return min(CGFloat(engine.remainingTime) / totalDuration, 1)
    }
    
    // MARK: - Buttons
    private func playPauseButton() -> some View {
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
    }
    
    private func resetButton() -> some View {
        Button {
            engine.reset()
            sendAction(.reset)
        } label: {
            Image(systemName: "arrow.counterclockwise")
        }
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
