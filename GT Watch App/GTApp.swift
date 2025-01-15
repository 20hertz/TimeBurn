//
//  GTApp.swift
//  GT Watch App
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

@main
struct TimerApp_watchOS: App {
    
    @StateObject private var timerManager = TimerManager.shared
    @StateObject private var connectivityProvider = WatchConnectivityProvider.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchHomeView()
            }
            .environmentObject(timerManager)
            .environmentObject(connectivityProvider)
            .onAppear {
                connectivityProvider.startSession()
            }
        }
    }
}
