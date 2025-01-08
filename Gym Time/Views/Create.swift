//
//  CreateView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//


import SwiftUI

struct CreateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timerModel: TimerModel
    @State private var name: String = ""
    @State private var activeDuration: Int = 30
    @State private var restDuration: Int = 10
    @State private var rounds: Int = 3
    
    var body: some View {
        Form {
            Section(header: Text("Timer Name")) {
                TextField("Name", text: $name)
            }
            
            Section(header: Text("Durations")) {
                Stepper("Active: \(activeDuration)s", value: $activeDuration, in: 5...600, step: 5)
                Stepper("Rest: \(restDuration)s", value: $restDuration, in: 5...600, step: 5)
            }
            
            Section(header: Text("Rounds")) {
                Stepper("\(rounds) rounds", value: $rounds, in: 1...20)
            }
            
            Button("Add Timer") {
                timerModel.addTimer(name: name, activeDuration: activeDuration, restDuration: restDuration, rounds: rounds)
                dismiss()
            }
            .disabled(name.isEmpty)
        }
        .navigationTitle("Create Timer")
    }
}
