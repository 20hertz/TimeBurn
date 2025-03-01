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

    // Timer settings with active seconds defaulting to 5 (active duration must be > 0).
    @State private var activeMinutes: Int = 0
    @State private var activeSeconds: Int = 5
    // For rounds, 0 represents infinite; 1 or higher means finite rounds.
    @State private var numberOfRounds: Int = 1
    @State private var restMinutes: Int = 0
    @State private var restSeconds: Int = 0   // Rest seconds can be 0.
    @State private var enableSound: Bool = true

    // TabView page tracking
    @State private var currentPage: Int = 0

    // Navigation state for new timer view
    @State private var navigateToNewTimer: Bool = false
    @State private var newTimerID: UUID? = nil

    // Computed durations (in seconds)
    var activeDuration: Int { activeMinutes * 60 + activeSeconds }
    var restDuration: Int { restMinutes * 60 + restSeconds }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header replaces the system navigation bar.
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button {
                        saveTimer()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black)

                // Main content: swipable settings pages.
                TabView(selection: $currentPage) {
                    // Page 0: Active Duration
                    VStack {
                        Text("Round Duration")
                            .font(.headline)
                            .padding(.top, 8)
                        TimePickerView(minutes: $activeMinutes, seconds: $activeSeconds)
                            .padding(.vertical)
                        Spacer()
                    }
                    .tag(0)
                    
                    // Page 1: Number of Rounds (with infinite option)
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
                    
                    if numberOfRounds != 1 {
                        // Page 2: Rest Time (shown only if rounds != 1)
                        VStack {
                            Text("Rest Time")
                                .font(.headline)
                                .padding(.top, 8)
                            TimePickerView(minutes: $restMinutes, seconds: $restSeconds, allowZero: true)
                                .padding(.vertical)
                            Spacer()
                        }
                        .tag(2)
                        
                        // Page 3: Sound toggle
                        VStack {
                            Toggle("Enable Sound", isOn: $enableSound)
                                .toggleStyle(SwitchToggleStyle())
                                .padding()
                            Spacer()
                        }
                        .tag(3)
                    } else {
                        // When numberOfRounds == 1, skip Rest Time and show Sound toggle as page 2.
                        VStack {
                            Toggle("Enable Sound", isOn: $enableSound)
                                .toggleStyle(SwitchToggleStyle())
                                .padding()
                            Spacer()
                        }
                        .tag(2)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .animation(.default, value: numberOfRounds)
            }
            .navigationBarHidden(true) // Hide the default navigation bar (and system clock)
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
            restDuration: restDuration,
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

/// A custom time picker view that lets the user select minutes and seconds.
/// The 'allowZero' parameter determines whether 0 seconds is a valid selection.
struct TimePickerView: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    var allowZero: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Minutes picker.
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
            .accentColor(Color.accentColor)

            Text(":")
                .font(.system(size: 24, weight: .bold))
                .padding(.horizontal, 4)

            // Seconds picker.
            if allowZero {
                Picker("", selection: $seconds) {
                    ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { sec in
                        Text(String(format: "%02d", sec))
                            .font(.system(size: 24, weight: seconds == sec ? .bold : .regular))
                            .foregroundColor(seconds == sec ? .primary : .gray)
                            .tag(sec)
                    }
                }
                .frame(width: 70)
                .clipped()
                .accentColor(Color.accentColor)
            } else {
                Picker("", selection: $seconds) {
                    ForEach(Array(stride(from: 5, through: 55, by: 5)), id: \.self) { sec in
                        Text(String(format: "%02d", sec))
                            .font(.system(size: 24, weight: seconds == sec ? .bold : .regular))
                            .foregroundColor(seconds == sec ? .primary : .gray)
                            .tag(sec)
                    }
                }
                .frame(width: 70)
                .clipped()
                .accentColor(Color.accentColor)
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
