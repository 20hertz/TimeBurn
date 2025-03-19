//
//  TimerView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-09.
//

import SwiftUI
import WatchKit

struct WatchTimerView: View {
    @ObservedObject var engine: TimerEngine
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider
    @Environment(\.dismiss) private var dismiss

    @State private var lastPhase: TimerEngine.Phase = .idle

    var body: some View {
        VStack(spacing: 12) {
            timeDisplay
            roundIndicators().padding(.top, 8)
            Spacer()
            controlButtons
        }
        .background(backgroundColor)
        .onChange(of: engine.phase) { newPhase in
            if newPhase == .active && lastPhase != .active {
                WKInterfaceDevice.current().play(.success)
            } else if newPhase == .rest && lastPhase != .rest {
                WKInterfaceDevice.current().play(.failure)
            }
            lastPhase = newPhase
        }
        .overlay(
            Group {
                if connectivityProvider.globalMusicPlaying {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .transition(.opacity)
                }
            },
            alignment: .bottomTrailing
        )
        .animation(.easeInOut, value: connectivityProvider.globalMusicPlaying)
    }
    
    private var timeDisplay: some View {
        HStack {
            Spacer()
            Text(formatTime(from: engine.remainingTime))
                .font(.system(.title, design: .monospaced))
            Spacer()
            editButton
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private var editButton: some View {
        NavigationLink(destination: WatchEditView(timer: engine.timer)) {
            Image(systemName: "gearshape")
                .imageScale(.large)
        }
        .fixedSize()
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
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            if engine.phase != .idle {
                Button(action: { localApply(.reset) }) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(engine.phase == .completed ? .accentColor : .white)
                }
            }
            if engine.phase != .completed {
                Button {
                    engine.isRunning ? localApply(.pause) : localApply(.play)
                } label: {
                    Image(systemName: engine.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(engine.phase == .idle ? .accentColor : .white)
                }
            }
        }
        .padding(.bottom, 20)
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
    
    private var currentButtonColor: Color {
        switch engine.phase {
        case .idle:
            return .accentColor
        case .active:
            return .green
        case .rest, .completed:
            return .red
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
