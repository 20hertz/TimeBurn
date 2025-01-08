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
                    Text(timer.name)
                }
                .onDelete(perform: timerModel.deleteTimer)
            }
            .navigationTitle("Gym Time")
            .toolbar {
                NavigationLink("Create", destination: CreateView())
            }
        }
    }
}
