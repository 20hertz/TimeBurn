//
//  WatchCreateView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-02-10.
//

import SwiftUI

struct WatchCreateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider

    // Timer settings with default seconds set to 5 so active duration is never 0.
    @State private var activeMinutes: Int = 0
    @State private var activeSeconds: Int = 5
    // For rounds, 0 represents infinite rounds; 1 or higher means finite rounds.
    @State private var numberOfRounds: Int = 1
    @State private var restMinutes: Int = 0
    @State private var restSeconds: Int = 5
    @State private var enableSound: Bool = true

    // TabView page tracking
    @State private var currentPage: Int = 0

    // Navigation state for new timer view
    @State private var navigateToNewTimer: Bool = false
    @State private var newTimerID: UUID? = nil

    // Computed durations
    var activeDuration: Int { activeMinutes * 60 + activeSeconds }
    var restDuration: Int { restMinutes * 60 + restSeconds }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main content: swipable settings pages.
                TabView(selection: $currentPage) {
                    VStack {
                        Text("Round Duration")
                            .font(.headline)
                            .padding(.top, 8)
                        TimePickerView(minutes: $activeMinutes, seconds: $activeSeconds)
                            .padding(.vertical)
                        Spacer()
                    }
                    .tag(0)
                    
                    VStack {
                        Text("Number of Rounds")
                            .font(.headline)
                            .padding(.top, 8)
                        Picker("", selection: $numberOfRounds) {
                            ForEach(0..<100, id: \.self) { round in
                                if round == 0 {
                                    Text("∞")
                                        .font(.system(size: 24, weight: numberOfRounds == round ? .bold : .regular))
                                        .foregroundColor(numberOfRounds == round ? .primary : .gray)
                                        .tag(round)
                                } else {
                                    Text("\(round)")
                                        .font(.system(size: 24, weight: numberOfRounds == round ? .bold : .regular))
                                        .foregroundColor(numberOfRounds == round ? .primary : .gray)
                                        .tag(round)
                                }
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    .tag(1)
                    
                    // Page 2: Rest Duration (shown only if numberOfRounds is not exactly 1)
                    if numberOfRounds != 1 {
                        VStack {
                            Text("Rest Time")
                                .font(.headline)
                                .padding(.top, 8)
                            // For rest duration, allow zero seconds.
                            TimePickerView(minutes: $restMinutes, seconds: $restSeconds, allowZero: true)
                                .padding(.vertical)
                            Spacer()
                        }
                        .tag(2)
                    }
                    
                    VStack {
                        Toggle("Enable Sound", isOn: $enableSound)
                            .toggleStyle(SwitchToggleStyle())
                            .padding()
                        Spacer()
                    }
                    .tag(numberOfRounds == 1 ? 2 : 3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .animation(.default, value: numberOfRounds)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top left cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                    }
                }
                // Top right save button styled with accentColor
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveTimer()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            // Hidden NavigationLink to push to the new timer's view upon saving.
            .background(
                NavigationLink(destination: destinationForNewTimer(), isActive: $navigateToNewTimer) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
    
    @ViewBuilder
    private func destinationForNewTimer() -> some View {
        if let id = newTimerID,
           let timer = timerManager.timers.first(where: { $0.id == id }) {
            let engine = ActiveTimerEngines.shared.engine(for: timer)
            WatchTimerView(engine: engine)
        } else {
            Text("Timer not found")
        }
    }
    
    private func saveTimer() {
        timerManager.addTimer(
            name: "",
            activeDuration: activeDuration,
            // If numberOfRounds is 1, restDuration is set to 0; otherwise use the chosen restDuration.
            restDuration: numberOfRounds == 1 ? 0 : restDuration,
            totalRounds: numberOfRounds,
            enableSound: enableSound
        )
        connectivityProvider.sendTimers(timerManager.timers)
        if let newTimer = timerManager.timers.last {
            newTimerID = newTimer.id
            navigateToNewTimer = true
        }
    }
}

// Helper view: TimePickerView with a parameter to allow 0 seconds.
struct TimePickerView: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    var allowZero: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Picker("", selection: $minutes) {
                ForEach(0..<60, id: \.self) { i in
                    Text("\(i)")
                        .font(.system(size: 24, weight: minutes == i ? .bold : .regular))
                        .foregroundColor(minutes == i ? .primary : .gray)
                        .tag(i)
                }
            }
            .frame(width: 70)
            .clipped()
            
            Text(":")
                .font(.system(size: 24, weight: .bold))
                .padding(.horizontal, 4)
            
            if allowZero {
                Picker("", selection: $seconds) {
                    ForEach(0..<12, id: \.self) { i in
                        let sec = i * 5
                        Text(String(format: "%02d", sec))
                            .font(.system(size: 24, weight: seconds == sec ? .bold : .regular))
                            .foregroundColor(seconds == sec ? .primary : .gray)
                            .tag(sec)
                    }
                }
                .frame(width: 70)
                .clipped()
            } else {
                Picker("", selection: $seconds) {
                    ForEach(1..<12, id: \.self) { i in
                        let sec = i * 5
                        Text(String(format: "%02d", sec))
                            .font(.system(size: 24, weight: seconds == sec ? .bold : .regular))
                            .foregroundColor(seconds == sec ? .primary : .gray)
                            .tag(sec)
                    }
                }
                .frame(width: 70)
                .clipped()
            }
        }
        .labelsHidden()
    }
}

#Preview {
    WatchCreateView()
        .environmentObject(TimerManager.shared)
        .environmentObject(WatchConnectivityProvider.shared)
}
