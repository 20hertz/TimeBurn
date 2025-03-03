//
//  HomeView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var timerManager: TimerManager
    @StateObject private var connectivityProvider = WatchConnectivityProvider.shared
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator

    @State private var navigateToSelectedTimer = false
    @State private var showingCreateView = false
    var body: some View {
        Group {
            if timerManager.timers.isEmpty {
                // Placeholder view when there are no timers.
                VStack(spacing: 8) {
                    Text("No timers created yet.")
                        .font(.headline)
                    Text("Create a new timer on your iOS device.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(timerManager.timers) { timer in
                        let engine = ActiveTimerEngines.shared.engine(for: timer)
                        RowView(timer: timer, engine: engine)
                    }
                }
            }
        }
        .navigationTitle("Timers")
        .toolbar {
            // Use .confirmationAction placement instead of .navigationBarTrailing on watchOS
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    showingCreateView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // Present WatchCreateView when needed
        .fullScreenCover(isPresented: $showingCreateView) {
            WatchCreateView()
                .environmentObject(timerManager)
                .environmentObject(connectivityProvider)
        }
        .conditionalNavigationDestination(isPresented: $navigateToSelectedTimer) {
            if let uuid = navigationCoordinator.selectedTimerID,
               let timer = timerManager.timers.first(where: { $0.id == uuid }) {
                let engine = ActiveTimerEngines.shared.engine(for: timer)
                WatchTimerView(engine: engine)
            } else {
                Text("Timer not found.")
            }
        }
        .conditionalOnChange(of: navigationCoordinator.selectedTimerID) { newValue in
            navigateToSelectedTimer = (newValue != nil)
        }
    }
}

struct RowView: View {
    let timer: IntervalTimer
    @ObservedObject var engine: TimerEngine

    var body: some View {
        NavigationLink(destination: WatchTimerView(engine: engine)) {
            HStack {
                VStack(alignment: .leading) {
                    if timer.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // No name provided – show the configuration string as headline.
                        Text(timer.configurationText)
                            .font(.headline)
                    } else {
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
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    let previewManager = TimerManager.shared
    // Uncomment one of these to test empty state versus list state:
    // previewManager.setTimers([])  // Empty state – shows placeholder message.
    previewManager.setTimers([
        IntervalTimer(name: "Circuit", activeDuration: 45, restDuration: 15, totalRounds: 6),
        IntervalTimer(name: "Sprint", activeDuration: 30, restDuration: 30, totalRounds: 5)
    ])
    
    return NavigationView {
        WatchHomeView()
            .environmentObject(previewManager)
    }
}

// Custom modifier for navigationDestination (requires watchOS 9+)
struct ConditionalNavigationDestination<Destination: View>: ViewModifier {
    @Binding var isPresented: Bool
    let destination: () -> Destination

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(watchOS 9.0, *) {
            content.navigationDestination(isPresented: $isPresented, destination: destination)
        } else {
            // For older versions, simply return the content unmodified.
            content
        }
    }
}

extension View {
    func conditionalNavigationDestination<Destination: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        self.modifier(ConditionalNavigationDestination(isPresented: isPresented, destination: destination))
    }
}

// Custom modifier for onChange (uses the new overload on watchOS 10+)
struct ConditionalOnChange<Value: Equatable>: ViewModifier {
    let value: Value
    let action: (Value) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(watchOS 10.0, *) {
            newOnChange(content: content)
        } else {
            oldOnChange(content: content)
        }
    }
    
    @available(watchOS 10.0, *)
    private func newOnChange<Content: View>(content: Content) -> some View {
        content.onChange(of: value, initial: false) { oldValue, newValue in
            action(newValue)
        }
    }
    
    private func oldOnChange<Content: View>(content: Content) -> some View {
        content.onChange(of: value) { newValue in
            action(newValue)
        }
    }
}

extension View {
    func conditionalOnChange<Value: Equatable>(
        of value: Value,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        self.modifier(ConditionalOnChange(value: value, action: action))
    }
}
