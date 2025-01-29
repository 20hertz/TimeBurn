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

            Text("REST")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .opacity(engine.phase == .rest ? 1.0 : 0.0)
                .frame(height: 30) // Reserve space to prevent layout shifts

            GeometryReader { geometry in
                CircularProgressBar(
                    progress: Double(progress),
                    remainingTime: engine.remainingTime,
                    isResting: engine.phase == .rest
                )
                .frame(width: geometry.size.width * 0.75,
                       height: geometry.size.width * 0.75)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .frame(height: UIScreen.main.bounds.width * 0.75)

            roundIndicator()

            HStack {
                if engine.phase != .idle {
                    resetButton()
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                        .clipShape(Circle())
                }

                Spacer()

                playPauseButton()
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }

            ToolbarItem(placement: .principal) {
                Text(engine.timer.name)
                    .font(.headline)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    EditView(timer: engine.timer)
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    // MARK: - Round Indicator
    @ViewBuilder
    private func roundIndicator() -> some View {
        if engine.timer.totalRounds > 1 {
            HStack(spacing: 8) {
                ForEach(0..<engine.timer.totalRounds, id: \.self) { index in
                    Circle()
                        .fill(index < engine.currentRound ? Color.accentColor : Color.gray.opacity(0.5))
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
                localApply(.pause)
            } else {
                localApply(.play)
            }
        } label: {
            Image(systemName: engine.isRunning ? "pause.circle.fill" : "play.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(20)
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 80)
        .background(Color.accentColor)
        .clipShape(Circle())
        .accessibilityLabel(engine.isRunning ? "Pause Timer" : "Play Timer")
        .accessibilityHint(engine.isRunning ? "Pauses the current timer." : "Starts the timer.")
    }

    private func resetButton() -> some View {
        Button {
            localApply(.reset)
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(15)
        }
        .accessibilityLabel("Reset Timer")
        .accessibilityHint("Resets the current timer to its initial state.")
        .accessibilityHidden(engine.phase == .idle)
    }

    private func localApply(_ action: TimerAction) {
        // 1) Build the local payload from the current engine state
        let eventTimestamp = Date()
        let payloadRemainingTime = engine.remainingTime
        let payloadIsRest = (engine.phase == .rest)
        let payloadCurrentRound = engine.currentRound

        // 2) Locally apply the action so we do “reset others + play/pause/etc.” all in applyAction
        engine.applyAction(
            action,
            eventTimestamp: eventTimestamp,
            payloadRemainingTime: payloadRemainingTime,
            payloadIsRest: payloadIsRest,
            payloadCurrentRound: payloadCurrentRound
        )

        // 3) Send the action across to the other device
        connectivityProvider.sendAction(timerID: engine.timer.id, action: action)
    }
}

#Preview {
    let sampleTimer = IntervalTimer(name: "Interval Timer", activeDuration: 60, restDuration: 30, totalRounds: 5)
    let engine = TimerEngine(timer: sampleTimer)
    return NavigationView {
        TimerView(engine: engine)
            .environmentObject(WatchConnectivityProvider.shared)
    }
}
