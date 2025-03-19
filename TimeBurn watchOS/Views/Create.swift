//
//  WatchCreateView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-02-10.
//

import SwiftUI

struct WatchCreateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider

    // Timer settings with active seconds defaulting to 5 (active duration must be > 0).
    @State private var activeMinutes: Int = 0
    @State private var activeSeconds: Int = 5
    // For rounds, 0 represents infinite; 1 or higher means finite rounds.
    @State private var numberOfRounds: Int = 1
    @State private var restMinutes: Int = 0
    @State private var restSeconds: Int = 0   // Rest seconds can be 0.
    @State private var enableSound: Bool = true

    // TabView page tracking
    @State private var currentPage: Int = 0

    // Navigation state for new timer view
    @State private var navigateToNewTimer: Bool = false
    @State private var newTimerID: UUID? = nil

    // Computed durations (in seconds)
    var activeDuration: Int { activeMinutes * 60 + activeSeconds }
    var restDuration: Int { restMinutes * 60 + restSeconds }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header replaces the system navigation bar.
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
                        saveTimer()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black)

                WatchTimerForm(activeMinutes: $activeMinutes,
                               activeSeconds: $activeSeconds,
                               numberOfRounds: $numberOfRounds,
                               restMinutes: $restMinutes,
                               restSeconds: $restSeconds,
                               enableSound: $enableSound)
            }
            .navigationBarHidden(true) // Hide the default navigation bar (and system clock)
            // Navigation to new timer view when saving.
            .background(
                NavigationLink(destination: destinationForNewTimer(), isActive: $navigateToNewTimer) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
    
    @ViewBuilder
    private func destinationForNewTimer() -> some View {
        if let id = newTimerID,
           let timer = timerManager.timers.first(where: { $0.id == id }) {
            let engine = ActiveTimerEngines.shared.engine(for: timer)
            WatchTimerView(engine: engine)
        } else {
            Text("Timer not found")
        }
    }
    
    private func saveTimer() {
        // Prevent saving a timer with 0:00 active duration.
        guard activeDuration > 0 else {
            // Optionally, you could show an alert here.
            return
        }
        
        timerManager.addTimer(
            name: "",
            activeDuration: activeDuration,
            restDuration: restDuration,
            totalRounds: numberOfRounds,
            enableSound: enableSound
        )
        connectivityProvider.sendTimers(timerManager.timers)
        if let newTimer = timerManager.timers.last {
            newTimerID = newTimer.id
            navigateToNewTimer = true
        }
    }
}

#Preview {
    WatchCreateView()
        .environmentObject(TimerManager.shared)
        .environmentObject(WatchConnectivityProvider.shared)
}
