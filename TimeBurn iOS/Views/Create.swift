//
//  CreateView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-13.
//

import SwiftUI

struct CreateView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var activeDuration: Int = 0
    @State private var restDuration: Int = 30
    @State private var totalRounds: Int = 0
    @State private var enableSound: Bool = true
    
    // New state variable for navigation after saving
    @State private var navigateToNewTimer: Bool = false
    
    // State variable for showing an alert if activeDuration is 0
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                TimerForm(
                    name: $name,
                    activeDuration: $activeDuration,
                    restDuration: $restDuration,
                    totalRounds: $totalRounds,
                    enableSound: $enableSound
                )
                .navigationTitle("Create Timer")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveTimer()
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToNewTimer) {
                destinationForNewTimer()
            }
            .alert("Invalid Timer", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Active duration must be greater than 0:00.")
            }
        }
    }

    private func destinationForNewTimer() -> some View {
        // Assuming the newly created timer is the last element in the timers array.
        if let newTimer = timerManager.timers.last {
            let engine = ActiveTimerEngines.shared.engine(for: newTimer)
            return AnyView(TimerView(engine: engine))
        } else {
            return AnyView(Text("Timer not found"))
        }
    }

    private func saveTimer() {
        // If active duration is 0, show alert instead of saving.
        guard activeDuration > 0 else {
            showAlert = true
            return
        }
        
        timerManager.addTimer(
            name: name,
            activeDuration: activeDuration,
            restDuration: restDuration,
            totalRounds: totalRounds,
            enableSound: enableSound
        )
        connectivityProvider.sendTimers(timerManager.timers)
        if timerManager.timers.last != nil {
            navigateToNewTimer = true
        }
    }
}

#Preview {
    NavigationStack {
        CreateView()
            .environmentObject(TimerManager.shared)
            .environmentObject(WatchConnectivityProvider.shared)
    }
}
