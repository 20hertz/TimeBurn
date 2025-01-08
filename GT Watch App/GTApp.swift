//
//  GTApp.swift
//  GT Watch App
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

@main
struct GymTime_WatchApp: App {
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
