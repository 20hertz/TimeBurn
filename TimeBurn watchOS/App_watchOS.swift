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
    @StateObject private var playbackMonitor = PlaybackMonitor()
    
    @ViewBuilder
    private func rootView() -> some View {
        if #available(watchOS 9.0, *) {
            NavigationStack {
                if timerManager.timers.isEmpty {
                    WatchCreateView()
                } else {
                    WatchHomeView()
                }
            }
        } else {
            NavigationView {
                if timerManager.timers.isEmpty {
                    WatchCreateView()
                } else {
                    WatchHomeView()
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            rootView()
                .environmentObject(timerManager)
                .environmentObject(connectivityProvider)
                .environmentObject(navigationCoordinator)
                .onAppear {
                    connectivityProvider.startSession()
                }
        }
    }
}
