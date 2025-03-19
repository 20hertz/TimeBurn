//
//  WatchEditView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-03-19.
//


import SwiftUI

struct WatchEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider

    let timer: IntervalTimer

    @State private var activeMinutes: Int = 0
    @State private var activeSeconds: Int = 0
    @State private var numberOfRounds: Int = 1
    @State private var restMinutes: Int = 0
    @State private var restSeconds: Int = 0
    @State private var enableSound: Bool = true

    init(timer: IntervalTimer) {
        self.timer = timer
        _activeMinutes = State(initialValue: timer.activeDuration / 60)
        _activeSeconds = State(initialValue: timer.activeDuration % 60)
        _restMinutes = State(initialValue: timer.restDuration / 60)
        _restSeconds = State(initialValue: timer.restDuration % 60)
        _numberOfRounds = State(initialValue: timer.totalRounds)
        _enableSound = State(initialValue: timer.enableSound)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button {
                        saveChanges()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black)

                // Reusable form view
                WatchTimerForm(activeMinutes: $activeMinutes,
                               activeSeconds: $activeSeconds,
                               numberOfRounds: $numberOfRounds,
                               restMinutes: $restMinutes,
                               restSeconds: $restSeconds,
                               enableSound: $enableSound)
            }
            .navigationBarHidden(true)
        }
    }

    private func saveChanges() {
        let activeDuration = activeMinutes * 60 + activeSeconds
        guard activeDuration > 0 else { return }
        let restDuration = restMinutes * 60 + restSeconds
        timerManager.updateTimer(timer,
                                 activeDuration: activeDuration,
                                 restDuration: restDuration,
                                 totalRounds: numberOfRounds,
                                 enableSound: enableSound)
        connectivityProvider.sendTimers(timerManager.timers)
        dismiss()
    }
}