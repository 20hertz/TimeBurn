//
//  Gym_TimeApp.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

@main
struct App_iOS: App {

    @StateObject private var timerManager = TimerManager.shared
    @StateObject private var connectivityProvider = WatchConnectivityProvider.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    
    private let audioManager = AudioManager.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(timerManager)
            .environmentObject(connectivityProvider)
            .environmentObject(navigationCoordinator)
            .onAppear {
                connectivityProvider.startSession()
            }
        }
    }
}
