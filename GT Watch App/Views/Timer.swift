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

            Text(formatTime(from: engine.remainingTime))
                .font(.system(.title, design: .monospaced))
                .padding(.top, 20)
            
            roundIndicators()
                .padding(.top, 8)
            
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
        .background(backgroundColor)
    }
    
    @ViewBuilder
    private func roundIndicators() -> some View {
        if engine.timer.totalRounds > 1 {
            HStack(spacing: 6) {
                ForEach(0..<engine.timer.totalRounds, id: \.self) { index in
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                        .background(Circle().fill(index < engine.currentRound ? Color.white : Color.clear))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        switch engine.phase {
        case .active:
            return .green
        case .rest:
            return .red
        default:
            return .clear
        }
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
