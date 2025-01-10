//
//  HomeView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerModel: TimerModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(timerModel.timers) { timer in
                    NavigationLink(destination: TimerView()) {
                        VStack(alignment: .leading) {
                            Text(timer.name)
                                .font(.headline)
                            Text("\(timer.rounds) x \(timer.activeDuration)s | \(timer.restDuration)s")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: timerModel.deleteTimer)
            }
            .toolbar {
                NavigationLink("Create", destination: CreateView())
            }
        }
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
