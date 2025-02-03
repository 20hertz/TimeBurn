//
//  TimerFormView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-27.
//


import SwiftUI

struct TimerForm: View {
    // Timer properties
    @Binding var name: String
    @Binding var activeDuration: Int
    @Binding var restDuration: Int
    @Binding var totalRounds: Int
    @Binding var enableSound: Bool

    var body: some View {
        Form {
            // Section for Timer Name
            Section(header: Text("Timer Name")) {
                TextField("Name", text: $name)
                    .disableAutocorrection(true)
            }

            // Section for Durations
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

            // Section for Rounds
            Section(header: Text("Rounds")) {
                Stepper("Rounds: \(totalRounds == 0 ? "∞" : "\(totalRounds)")", value: $totalRounds, in: 0...100)
            }

            // Section for Bell Sounds
            Section {
                Toggle(isOn: $enableSound) {
                    Text("Bell Sound")
                }
            }
        }
    }
}
