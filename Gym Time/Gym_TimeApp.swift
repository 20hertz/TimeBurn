//
//  Gym_TimeApp.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

@main
struct GymTimeApp: App {
    @StateObject private var timerModel = TimerModel()

    init() {
        _ = WatchConnector.shared // Activate and retain shared instance
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(timerModel)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(TimerModel())
}
