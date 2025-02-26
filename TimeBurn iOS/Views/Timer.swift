//
//  TimerView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-13.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider
    @ObservedObject var engine: TimerEngine
    @Environment(\.dismiss) private var dismiss

    // Computed property for button color based on timer phase.
    private var currentButtonColor: Color {
        switch engine.phase {
        case .idle:
            return Color.accentColor
        case .active:
            return Color.green
        case .rest, .completed:
            return Color.red
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {

            Text("Rest")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .opacity(engine.phase == .rest ? 1.0 : 0.0)
                .frame(height: 30) // Reserve space to prevent layout shifts

            GeometryReader { geometry in
                CircularProgressBar(
                    progress: Double(progress),
                    remainingTime: engine.remainingTime,
                    color: currentButtonColor
                )
                .frame(width: geometry.size.width * 0.75,
                       height: geometry.size.width * 0.75)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .frame(height: UIScreen.main.bounds.width * 0.75)

            roundIndicator()

            HStack {
                // Left Side: Reset Button or Spacer
                if engine.phase != .idle && engine.phase != .completed {
                    resetButton()
                        .frame(width: 60, height: 60)
                } else {
                    Spacer()
                        .frame(width: 60, height: 60) // Maintain alignment when resetButton is hidden
                }

                Spacer()

                // Center: Play/Pause or Reset button when completed
                playPauseButton()
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)

                Spacer()

                // Right Side: Invisible Placeholder to Balance HStack
                if engine.phase != .idle {
                    resetButton()
                        .frame(width: 60, height: 60)
                        .hidden() // Invisible to balance the HStack
                } else {
                    Spacer()
                        .frame(width: 60, height: 60)
                }
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
                        .fill(index < engine.currentRound ? currentButtonColor : Color.gray.opacity(0.5))
                        .frame(width: 20, height: 20)
                }
            }
        }
    }

    // MARK: - Helpers
    private var progress: CGFloat {
        let totalDuration: CGFloat = (engine.phase == .rest)
            ? CGFloat(engine.timer.restDuration)
            : CGFloat(engine.timer.activeDuration)
        return min(CGFloat(engine.remainingTime) / totalDuration, 1)
    }

    // MARK: - Buttons
    private func playPauseButton() -> some View {
        if engine.phase == .completed {
            // When completed, show reset button instead (with a ZStack to avoid clipping).
            return AnyView(
                Button {
                    localApply(.reset)
                } label: {
                    ZStack {
                        Circle()
                            .foregroundColor(currentButtonColor)
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(15)
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel("Reset Timer")
                .accessibilityHint("Resets the timer to its initial state.")
            )
        } else {
            return AnyView(
                Button {
                    if engine.isRunning {
                        localApply(.pause)
                    } else {
                        localApply(.play)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .foregroundColor(currentButtonColor)
                        Image(systemName: engine.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel(engine.isRunning ? "Pause Timer" : "Play Timer")
                .accessibilityHint(engine.isRunning ? "Pauses the timer." : "Starts the timer.")
            )
        }
    }

    private func resetButton() -> some View {
        Button {
            localApply(.reset)
        } label: {
            ZStack {
                Circle()
                    .stroke(currentButtonColor, lineWidth: 2)
                Image(systemName: "arrow.counterclockwise")
                    .resizable()
                    .scaledToFit()
                    .padding(15)
                    .foregroundColor(currentButtonColor)
            }
        }
        .accessibilityLabel("Reset Timer")
        .accessibilityHint("Resets the current timer to its initial state.")
        .accessibilityHidden(engine.phase == .idle)
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
    let sampleTimer = IntervalTimer(name: "Interval Timer", activeDuration: 60, restDuration: 30, totalRounds: 5)
    let engine = TimerEngine(timer: sampleTimer)
    return NavigationView {
        TimerView(engine: engine)
            .environmentObject(WatchConnectivityProvider.shared)
    }
}
