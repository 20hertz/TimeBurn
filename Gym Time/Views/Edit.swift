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
    @State private var activeDuration: String
    @State private var restDuration: String
    @State private var totalRounds: String

    // Initialize the state with the timer's current values.
    init(timer: IntervalTimer) {
        self.timer = timer
        _name = State(initialValue: timer.name)
        _activeDuration = State(initialValue: "\(timer.activeDuration)")
        _restDuration = State(initialValue: "\(timer.restDuration)")
        _totalRounds = State(initialValue: "\(timer.totalRounds)")
    }

    var body: some View {
        Form {
            Section(header: Text("Edit Timer Details")) {
                TextField("Name", text: $name)
                TextField("Active Duration (seconds)", text: $activeDuration)
                    .keyboardType(.numberPad)
                TextField("Rest Duration (seconds)", text: $restDuration)
                    .keyboardType(.numberPad)
                TextField("Total Rounds (0 = infinite)", text: $totalRounds)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Edit Timer")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.isEmpty ||
                          activeDuration.isEmpty ||
                          restDuration.isEmpty ||
                          totalRounds.isEmpty)
            }
        }
    }

    private func saveChanges() {
        guard let active = Int(activeDuration),
              let rest = Int(restDuration),
              let rounds = Int(totalRounds) else { return }
        timerManager.updateTimer(timer, name: name, activeDuration: active, restDuration: rest, totalRounds: rounds)
        
        connectivityProvider.sendTimers(timerManager.timers)
        dismiss()
    }
}

#Preview {
    NavigationView {
        // Create a sample timer for preview purposes.
        let sampleTimer = IntervalTimer(name: "Sample Timer", activeDuration: 60, restDuration: 30, totalRounds: 5)
        EditView(timer: sampleTimer)
            .environmentObject(TimerManager.shared)
            .environmentObject(WatchConnectivityProvider.shared)
    }
}
