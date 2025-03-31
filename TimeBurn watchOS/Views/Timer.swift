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
    @State private var inactivityTimer: Timer? = nil
    @State private var volumeReduced: Bool = false
    
    @Namespace private var animationNamespace
    
    var startFocused: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background: use backgroundColor when focused, else clear.
                (isFocused ? backgroundColor : Color.clear)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut, value: isFocused)
                
                // Normal layout
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        // Show only the time display here with the matchedGeometryEffect.
                        timeDisplay
                            .matchedGeometryEffect(id: "timeDisplay", in: animationNamespace)
                            .opacity(isFocused ? 0 : 1)
                            .onTapGesture {
                                withAnimation(.easeInOut) { isFocused = true }
                            }
                        Spacer()
                        editButton
                            .offset(x: isFocused ? 200 : 0)
                            .animation(.easeInOut, value: isFocused)
                        Spacer()
                    }

                    roundIndicator()
                        .matchedGeometryEffect(id: "roundIndicator", in: animationNamespace)
                        .opacity(isFocused ? 0 : 1)
                        .animation(.easeInOut, value: isFocused)
                    Spacer()
                    controlButtons
                        .offset(y: isFocused ? 200 : 0)
                        .animation(.easeInOut, value: isFocused)
                }

                if isFocused {
                    // Focus view: overlay the time display (with matched geometry) centered and scaled up.
                    timeDisplay
                        .matchedGeometryEffect(id: "timeDisplay", in: animationNamespace)
                        .scaleEffect(1.5)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .onTapGesture {
                            withAnimation(.easeInOut) { isFocused = false }
                        }
                    // In the focus view overlay (inside the if isFocused block), update the round indicator as follows:
                    roundIndicator()
                        .matchedGeometryEffect(id: "roundIndicator", in: animationNamespace)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2 + 40)
                        .animation(.easeInOut, value: isFocused)
                }
            }
        }
        .onAppear {
            if startFocused {
                withAnimation(.easeInOut) {
                    isFocused = true
                }
            }
            
            startInactivityTimer()
            
            volumeReduced = false
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
            
            startInactivityTimer()
        }
        .onChange(of: isFocused) { _ in
            startInactivityTimer()
        }
        .onChange(of: connectivityProvider.globalMusicPlaying) { newValue in
            // Force UI update when global music playing state changes
            withAnimation(.easeInOut) {
                // This empty animation block will ensure the UI updates
                // when the globalMusicPlaying property changes
            }
        }
        .onTapGesture {
             if isFocused {
                 withAnimation(.easeInOut) {
                     isFocused = false
                 }
             }
            
            startInactivityTimer()
        }
        .overlay(
            Group {
                if connectivityProvider.globalMusicPlaying {
                    Button(action: {
                        toggleVolumeReduction()
                    }) {
                        Image(systemName: volumeReduced ? "music.note.list" : "music.note")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(8)
                            .foregroundColor(volumeReduced ? .orange : .white)
                    }
                    .background(Circle().fill(Color.black.opacity(0.3)))
                    .fixedSize()
                    .transition(.opacity)
                }
            },
            alignment: .bottomTrailing
        )
        .animation(.easeInOut, value: connectivityProvider.globalMusicPlaying)
        .animation(.easeInOut, value: volumeReduced)
    }
    
    private func toggleVolumeReduction() {
        volumeReduced.toggle()
        connectivityProvider.sendVolumeControl(reduce: volumeReduced)
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(volumeReduced ? .click : .notification)
    }
    
    private func startInactivityTimer() {
        // Invalidate any existing timer
        inactivityTimer?.invalidate()
            
        // Only start timer if engine is running AND not already focused
        // When a user manually pauses, engine.isRunning becomes false,
        // so we shouldn't auto-focus in that case
        guard engine.isRunning && !isFocused else { return }
            
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(.easeInOut) {
                isFocused = true
            }
        }
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

    private var timeAndRoundView: some View {
        VStack(spacing: 8) {
            timeDisplay
            roundIndicator()
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
    private func roundIndicator() -> some View {
        if engine.timer.totalRounds > 1 {
            let roundsText = engine.timer.totalRounds == 0 ? "∞" : "\(engine.timer.totalRounds)"
            Text("\(engine.currentRound)/\(roundsText)")
                .font(.caption2)
                .foregroundColor(.white)
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
                        inactivityTimer?.invalidate()
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
