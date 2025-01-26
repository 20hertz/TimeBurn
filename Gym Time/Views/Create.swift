//
//  CreateView.swift
//  Gym Time
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

    var body: some View {
        Form {
            Section(header: Text("Timer Name")) {
                TextField("Name", text: $name)
                    .disableAutocorrection(true)
            }

            Section(header: Text("Durations")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Time")
                        .font(.subheadline)
                    DurationPicker(duration: $activeDuration)
                        .frame(height: 150)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest Time")
                        .font(.subheadline)
                    DurationPicker(duration: $restDuration)
                        .frame(height: 150)
                }
            }

            Section(header: Text("Rounds")) {
                Stepper("Rounds: \(totalRounds == 0 ? "∞" : "\(totalRounds)")", value: $totalRounds, in: 0...100)
            }
        }
        .navigationTitle("Create Timer")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTimer()
                }
                .disabled(name.isEmpty)
            }
        }
    }

    private func saveTimer() {
        timerManager.addTimer(name: name, activeDuration: activeDuration, restDuration: restDuration, totalRounds: totalRounds)
        connectivityProvider.sendTimers(timerManager.timers)
        dismiss()
    }
}

#Preview {
    NavigationView {
        CreateView()
            .environmentObject(TimerManager.shared)
            .environmentObject(WatchConnectivityProvider.shared)
    }
}
