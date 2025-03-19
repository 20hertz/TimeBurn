//
//  WatchTimerForm.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-03-19.
//

import SwiftUI

struct WatchTimerForm: View {
    @Binding var activeMinutes: Int
    @Binding var activeSeconds: Int
    @Binding var numberOfRounds: Int
    @Binding var restMinutes: Int
    @Binding var restSeconds: Int
    @Binding var enableSound: Bool
    @State private var currentPage: Int = 0

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 0: Round Duration
            VStack {
                Text("Round Duration")
                    .font(.headline)
                    .padding(.top, 8)
                TimePickerView(minutes: $activeMinutes, seconds: $activeSeconds)
                    .padding(.vertical)
                Spacer()
            }
            .tag(0)

            // Page 1: Number of Rounds
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

            // Conditional pages for rest time and sound toggle
            if numberOfRounds != 1 {
                VStack {
                    Text("Rest Time")
                        .font(.headline)
                        .padding(.top, 8)
                    TimePickerView(minutes: $restMinutes, seconds: $restSeconds, allowZero: true)
                        .padding(.vertical)
                    Spacer()
                }
                .tag(2)

                VStack {
                    Toggle("Enable Sound", isOn: $enableSound)
                        .toggleStyle(SwitchToggleStyle())
                        .padding()
                    Spacer()
                }
                .tag(3)
            } else {
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
