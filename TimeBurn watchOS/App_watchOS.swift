//
//  GTApp.swift
//  TimeBurn watchOS
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

@main
struct App_watchOS: App {
    
    @StateObject private var timerManager = TimerManager.shared
    @StateObject private var connectivityProvider = WatchConnectivityProvider.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if timerManager.timers.isEmpty {
                    WatchCreateView()
                } else {
                    WatchHomeView()
                }
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
