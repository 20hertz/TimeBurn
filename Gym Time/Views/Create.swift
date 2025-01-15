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
    @State private var activeDuration: String = ""
    @State private var restDuration: String = ""
    @State private var totalRounds: String = ""

    var body: some View {
        Form {
            Section(header: Text("Timer Details")) {
                TextField("Name", text: $name)
                TextField("Active Duration (seconds)", text: $activeDuration)
                    .keyboardType(.numberPad)
                TextField("Rest Duration (seconds)", text: $restDuration)
                    .keyboardType(.numberPad)
                TextField("Total Rounds (0 = infinite)", text: $totalRounds)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Create Timer")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTimer()
                }
                .disabled(name.isEmpty ||
                          activeDuration.isEmpty ||
                          restDuration.isEmpty ||
                          totalRounds.isEmpty)
            }
        }
    }

    private func saveTimer() {
        guard let active = Int(activeDuration),
              let rest = Int(restDuration),
              let rounds = Int(totalRounds) else { return }
        timerManager.addTimer(name: name, activeDuration: active, restDuration: rest, totalRounds: rounds)
        
        connectivityProvider.sendTimers(timerManager.timers)
        dismiss()
    }
}

#Preview {
    NavigationView {
        CreateView()
            .environmentObject(TimerManager.shared)
    }
}
