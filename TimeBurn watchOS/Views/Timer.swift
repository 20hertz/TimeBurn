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
    @State private var isFocused: Bool = false
    
    @Namespace private var animationNamespace

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background: use backgroundColor when focused, else clear.
                (isFocused ? backgroundColor : Color.clear)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut, value: isFocused)
                
                // Normal layout: use the grouped timeAndRoundView for time display and round indicators.
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        timeAndRoundView
                            .matchedGeometryEffect(id: "timeAndRound", in: animationNamespace)
                            .opacity(isFocused ? 0 : 1)
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    isFocused = true
                                }
                            }
                        Spacer()
                        editButton
                            .offset(x: isFocused ? 200 : 0)
                            .animation(.easeInOut, value: isFocused)
                        Spacer()
                    }
                    Spacer()
                    controlButtons
                        .offset(y: isFocused ? 200 : 0)
                        .animation(.easeInOut, value: isFocused)
                }
                
                // Overlay focused view: show the grouped container centered and scaled up.
                if isFocused {
                    timeAndRoundView
                        .matchedGeometryEffect(id: "timeAndRound", in: animationNamespace)
                        .scaleEffect(1.5)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .onTapGesture {
                            withAnimation(.easeInOut) { isFocused = false }
                        }
                }
            }
        }
        .onChange(of: engine.phase) { newPhase in
             if newPhase == .active && lastPhase != .active {
                 WKInterfaceDevice.current().play(.success)
                 withAnimation(.easeInOut) {
                     isFocused = true
                 }
             } else if newPhase == .rest && lastPhase != .rest {
                 WKInterfaceDevice.current().play(.failure)
             }
             lastPhase = newPhase
        }
        .onTapGesture {
             if isFocused {
                 withAnimation(.easeInOut) {
                     isFocused = false
                 }
             }
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
        Text(formatTime(from: engine.remainingTime))
            .font(.system(.title, design: .monospaced))
            .foregroundColor(isFocused ? .primary : .accentColor)
    }
    
    // Computes the offset for time display so that it slides from its normal (top-center) position to the center.
    private func timeDisplayOffset(in size: CGSize) -> CGSize {
        if isFocused {
             // Assume normal view position is approximately at y = 50.
             let normalY: CGFloat = 50
             let targetY = size.height / 2
             let verticalOffset = targetY - normalY
             // No horizontal offset for perfect centering.
             return CGSize(width: 0, height: verticalOffset)
        } else {
             return .zero
        }
    }

    // Slides the edit button to the right when focused.
    private func editButtonOffset(in size: CGSize) -> CGSize {
        if isFocused {
            return CGSize(width: 200, height: 0)
        } else {
            return .zero
        }
    }

    // Slides the control buttons off the bottom when focused.
    private func controlButtonsOffset(in size: CGSize) -> CGSize {
        if isFocused {
            return CGSize(width: 0, height: 200)
        } else {
            return .zero
        }
    }

    // Slides the round indicators off the bottom when focused.
    private func roundIndicatorsOffset(in size: CGSize) -> CGSize {
        if isFocused {
            return CGSize(width: 0, height: 200)
        } else {
            return .zero
        }
    }
    
    // Add the following computed property below the existing timeDisplay property:
    private var timeAndRoundView: some View {
        VStack(spacing: 8) {
            timeDisplay
            roundIndicators()
        }
    }
    
    private var editButton: some View {
        NavigationLink(destination: WatchEditView(timer: engine.timer)) {
            Image(systemName: "gearshape")
                .imageScale(.large)
        }
        .fixedSize()
        .offset(x: isFocused ? 200 : 0)
        .animation(.easeInOut, value: isFocused)
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
                    if !engine.isRunning {
                        withAnimation(.easeInOut) {
                            isFocused = true
                        }
                        localApply(.play)
                    } else {
                        localApply(.pause)
                    }
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
