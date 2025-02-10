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

    // Default values (in seconds, except rounds which is an Int; 0 means infinite rounds)
    @State private var activeDuration: Int = 60
    @State private var restDuration: Int = 30
    @State private var totalRounds: Int = 0
    @State private var enableSound: Bool = true

    var body: some View {
        Form {
            // Active Duration Row
            HStack {
                Text("Active")
                Spacer()
                // Using a Stepper for a compact, wheel-like selection.
                Stepper("\(formatTime(from: activeDuration))", value: $activeDuration, in: 10...600, step: 5)
                    .labelsHidden()
            }
            
            // Rest Duration Row
            HStack {
                Text("Rest")
                Spacer()
                Stepper("\(formatTime(from: restDuration))", value: $restDuration, in: 0...300, step: 5)
                    .labelsHidden()
            }
            
            // Rounds Row
            HStack {
                Text("Rounds")
                Spacer()
                Picker("", selection: $totalRounds) {
                    Text("∞").tag(0)
                    ForEach(1..<21) { round in
                        Text("\(round)").tag(round)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(maxWidth: 60)
            }
            
            // Sound Toggle Row
            Toggle("Sound", isOn: $enableSound)
        }
        .navigationTitle("New Timer")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTimer()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func saveTimer() {
        // Create a timer with an empty name (since name is optional)
        timerManager.addTimer(
            name: "",
            activeDuration: activeDuration,
            restDuration: restDuration,
            totalRounds: totalRounds,
            enableSound: enableSound
        )
        connectivityProvider.sendTimers(timerManager.timers)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        WatchCreateView()
            .environmentObject(TimerManager.shared)
            .environmentObject(WatchConnectivityProvider.shared)
    }
}
