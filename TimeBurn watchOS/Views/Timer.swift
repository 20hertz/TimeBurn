//
//  TimerView.swift
//  TimeBurn
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
                        localApply(.reset)
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                
                Button {
                    if engine.isRunning {
                        localApply(.pause)
                    } else {
                        localApply(.play)
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
    
    private func localApply(_ action: TimerAction) {
        let eventTimestamp = Date()
        let payloadRemainingTime = engine.remainingTime
        let payloadIsRest = (engine.phase == .rest)
        let payloadCurrentRound = engine.currentRound
        
        engine.applyAction(
            action,
            eventTimestamp: eventTimestamp,
            payloadRemainingTime: payloadRemainingTime,
            payloadIsRest: payloadIsRest,
            payloadCurrentRound: payloadCurrentRound
        )
        
        connectivityProvider.sendAction(timerID: engine.timer.id, action: action)
    }

}

#Preview {
    let sampleTimer = IntervalTimer(name: "Watch Timer", activeDuration: 45, restDuration: 15, totalRounds: 4)
    let engine = TimerEngine(timer: sampleTimer)
    return WatchTimerView(engine: engine)
}
