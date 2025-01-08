//
//  HomeView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var connector = WatchConnector.shared

    var body: some View {
        List {
            ForEach(connector.timers) { timer in
                Text(timer.name)
            }
        }
        .navigationTitle("Gym Time")
    }
}

#Preview {
    let sampleModel = TimerModel()
    sampleModel.timers = [
        Timer(id: UUID(), name: "Timer A", activeDuration: 30, restDuration: 10, rounds: 5, remainingTime: 30),
        Timer(id: UUID(), name: "Timer B", activeDuration: 45, restDuration: 15, rounds: 3, remainingTime: 45)
    ]
    return HomeView()
        .environmentObject(sampleModel)
}
