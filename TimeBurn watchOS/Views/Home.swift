//
//  HomeView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

struct WatchHomeView: View {
    // MARK: - Properties
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @StateObject private var connectivityProvider = WatchConnectivityProvider.shared

    @State private var navigateToSelectedTimer = false
    @State private var showingCreateView = false
    
    // MARK: - Body
    var body: some View {
        Group {
            if timerManager.timers.isEmpty {
                emptyStateView
            } else {
                timerListView
            }
        }
        .navigationTitle("Timers")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { showingCreateView = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fullScreenCover(isPresented: $showingCreateView) {
            WatchCreateView()
                .environmentObject(timerManager)
                .environmentObject(connectivityProvider)
        }
        .modifier(WatchVersionCompatibilityModifier(
            navigateToSelectedTimer: $navigateToSelectedTimer,
            selectedTimerID: navigationCoordinator.selectedTimerID,
            timerManager: timerManager
        ))
    }
    
    // MARK: - Component Views
    
    /// View displayed when no timers exist
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("No timers created yet.")
                .font(.headline)
            Text("Create a new timer on your iOS device.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// List of existing timers
    private var timerListView: some View {
        List {
            ForEach(timerManager.timers) { timer in
                let engine = ActiveTimerEngines.shared.engine(for: timer)
                RowView(timer: timer, engine: engine)
            }
        }
    }
}

// MARK: - Supporting Structures

/// Handles version-specific navigation logic
struct WatchVersionCompatibilityModifier: ViewModifier {
    @Binding var navigateToSelectedTimer: Bool
    let selectedTimerID: UUID?
    let timerManager: TimerManager
    
    func body(content: Content) -> some View {
        if #available(watchOS 9.0, *) {
            content
                .navigationDestination(isPresented: $navigateToSelectedTimer) {
                    timerDestinationView
                }
                .onChange(of: selectedTimerID) { newValue in
                    navigateToSelectedTimer = (newValue != nil)
                }
        } else {
            content
                .onChange(of: selectedTimerID) { newValue in
                    navigateToSelectedTimer = (newValue != nil)
                }
        }
    }
    
    @ViewBuilder
    private var timerDestinationView: some View {
        if let uuid = selectedTimerID,
           let timer = timerManager.timers.first(where: { $0.id == uuid }) {
            let engine = ActiveTimerEngines.shared.engine(for: timer)
            WatchTimerView(engine: engine, startFocused: true)
        } else {
            Text("Timer not found.")
        }
    }
}

// MARK: - Preview

#Preview {
    let previewManager = TimerManager.shared
    previewManager.setTimers([
        IntervalTimer(name: "Circuit", activeDuration: 45, restDuration: 15, totalRounds: 6),
        IntervalTimer(name: "Sprint", activeDuration: 30, restDuration: 30, totalRounds: 5)
    ])
    
    return NavigationView {
        WatchHomeView()
            .environmentObject(previewManager)
            .environmentObject(NavigationCoordinator.shared)
    }
}

struct RowView: View {
    let timer: IntervalTimer
    @ObservedObject var engine: TimerEngine

    var body: some View {
        NavigationLink(destination: WatchTimerView(engine: engine)) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if timer.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // When no name is provided, show the configuration text.
                        Text(timer.configurationText)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // Display timer name and configuration text.
                        Text(timer.name)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(timer.configurationText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if engine.isRunning {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 4)
            .frame(height: 50) // Fixed row height
        }
    }
}
