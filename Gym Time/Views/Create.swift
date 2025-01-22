//
//  CreateView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-13.
//

import SwiftUI

/// A custom duration picker that lets the user select minutes and seconds.
/// The duration is stored in seconds.
struct DurationPicker: View {
    @Binding var duration: Int // duration in seconds

    var body: some View {
        HStack(spacing: 16) {
            // Minutes Picker – fill available space.
            Picker("Minutes", selection: Binding(
                get: { duration / 60 },
                set: { newMinutes in
                    // Set minutes portion while preserving seconds.
                    duration = newMinutes * 60 + (duration % 60)
                }
            )) {
                ForEach(0..<60, id: \.self) { minute in
                    Text("\(minute) min")
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()

            // Seconds Picker – now using 5-second increments.
            Picker("Seconds", selection: Binding(
                get: {
                    // Round down to the nearest multiple of 5.
                    let secs = duration % 60
                    return secs - (secs % 5)
                },
                set: { newSeconds in
                    // Set the seconds to newSeconds (which is in increments of 5) while preserving minutes.
                    duration = (duration / 60) * 60 + newSeconds
                }
            )) {
                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { second in
                    Text("\(second) sec")
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
        }
    }
}

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
