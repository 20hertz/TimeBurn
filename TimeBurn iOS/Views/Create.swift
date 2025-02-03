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

    var body: some View {
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
                .disabled(name.isEmpty)
            }
        }
    }


    private func saveTimer() {
        timerManager.addTimer(name: name, activeDuration: activeDuration, restDuration: restDuration, totalRounds: totalRounds, enableSound: enableSound)
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
