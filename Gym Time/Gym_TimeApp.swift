//
//  Gym_TimeApp.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

@main
struct TimerApp_iOS: App {

    @StateObject private var timerManager = TimerManager.shared
    @StateObject private var connectivityProvider = WatchConnectivityProvider.shared

    private let audioManager = AudioManager.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(timerManager)
            .environmentObject(connectivityProvider)
            .onAppear {
                connectivityProvider.startSession()
            }
        }
    }
}
