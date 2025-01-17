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
            timerDisplay()
            roundIndicator()
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
    
    private func timerDisplay() -> some View {
        VStack(spacing: 16) {
            Text("REST")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black)
                .opacity(engine.phase == .rest ? 1.0 : 0.0)
                .padding(.bottom, 8)
            CircularProgressBar(
                progress: progress,
                remainingTime: engine.remainingTime
            )
                .frame(width: 250, height: 250)
                .padding(.top, 40)
        }
    }
    
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
    

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private var progress: CGFloat {
        let totalDuration: CGFloat
        if engine.phase == .rest {
            totalDuration = CGFloat(engine.timer.restDuration)
        } else {
            totalDuration = CGFloat(engine.timer.activeDuration)
        }
        return min(CGFloat(engine.remainingTime) / totalDuration, 1)
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
