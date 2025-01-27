//
//  EditView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-13.
//

import SwiftUI

struct EditView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider
    @Environment(\.dismiss) var dismiss

    // The timer being edited
    let timer: IntervalTimer

    // State properties pre-filled with existing values.
    @State private var name: String
    @State private var activeDuration: Int
    @State private var restDuration: Int
    @State private var totalRounds: Int
    @State private var enableSound: Bool

    // Alert properties
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Initialize the state with the timer's current values.
    init(timer: IntervalTimer) {
        self.timer = timer
        _name = State(initialValue: timer.name)
        _activeDuration = State(initialValue: timer.activeDuration)
        _restDuration = State(initialValue: timer.restDuration)
        _totalRounds = State(initialValue: timer.totalRounds)
        _enableSound = State(initialValue: timer.enableSound)
    }

    var body: some View {
        NavigationView {
            TimerForm(name: $name,
                         activeDuration: $activeDuration,
                         restDuration: $restDuration,
                         totalRounds: $totalRounds,
                         enableSound: $enableSound)
                .navigationTitle("Edit Timer")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Update") {
                            saveChanges()
                        }
                        .disabled(name.isEmpty || activeDuration <= 0)
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Invalid Input"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
        }
    }

    private func saveChanges() {
        // Validate inputs
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Timer name cannot be empty."
            showingAlert = true
            return
        }

        guard activeDuration > 0 else {
            alertMessage = "Active duration must be greater than zero."
            showingAlert = true
            return
        }

        // Update the timer in TimerManager
        timerManager.updateTimer(timer, name: name, activeDuration: activeDuration, restDuration: restDuration, totalRounds: totalRounds, enableSound: enableSound)
        
        // Synchronize with connected devices
        connectivityProvider.sendTimers(timerManager.timers)
        
        // Dismiss the view
        dismiss()
    }
}

#Preview {
    NavigationView {
        // Create a sample timer for preview purposes.
        let sampleTimer = IntervalTimer(name: "Sample Timer", activeDuration: 60, restDuration: 30, totalRounds: 5, enableSound: true)
        EditView(timer: sampleTimer)
            .environmentObject(TimerManager.shared)
            .environmentObject(WatchConnectivityProvider.shared)
    }
}
