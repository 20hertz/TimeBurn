//
//  DurationPicker.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-26.
//

import SwiftUI

/// A custom duration picker that lets the user select minutes and seconds.
/// The duration is stored in seconds.
struct DurationPicker: View {
    @Binding var duration: Int // duration in seconds

    var body: some View {
        HStack(spacing: 16) {
            // Minutes Picker – fill available space.
            Picker("Minutes", selection: Binding(
                get: { duration / 60 },
                set: { newMinutes in
                    // Set minutes portion while preserving seconds.
                    duration = newMinutes * 60 + (duration % 60)
                }
            )) {
                ForEach(0..<60, id: \.self) { minute in
                    Text("\(minute) min")
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()

            // Seconds Picker – now using 5-second increments.
            Picker("Seconds", selection: Binding(
                get: {
                    // Round down to the nearest multiple of 5.
                    let secs = duration % 60
                    return secs - (secs % 5)
                },
                set: { newSeconds in
                    // Set the seconds to newSeconds (which is in increments of 5) while preserving minutes.
                    duration = (duration / 60) * 60 + newSeconds
                }
            )) {
                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { second in
                    Text("\(second) sec")
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
        }
    }
}
