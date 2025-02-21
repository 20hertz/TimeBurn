//
//  TimerFormView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-27.
//

import SwiftUI

struct TimerForm: View {
    @Binding var name: String
    @Binding var activeDuration: Int
    @Binding var restDuration: Int
    @Binding var totalRounds: Int
    @Binding var enableSound: Bool

    var body: some View {
        Form {
            Section() {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round Duration")
                        .font(.subheadline)
                    DurationPicker(duration: $activeDuration)
                        .frame(height: 150)
                }
            }

            Section(header: Text("Rounds")) {
                Stepper(totalRounds == 0 ? "∞" : "\(totalRounds)", value: $totalRounds, in: 0...100)
            }
            
            Section() {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest Time")
                        .font(.subheadline)
                    DurationPicker(duration: $restDuration)
                        .frame(height: 150)
                }
            }

            Section {
                Toggle(isOn: $enableSound) {
                    Text("Bell Sound")
                }
            }
            
            Section(header: Text("Timer Name")) {
                TextField("Name", text: $name)
                    .disableAutocorrection(true)
            }
        }
    }
}
