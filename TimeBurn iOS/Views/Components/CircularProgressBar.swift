//
//  CircularProgressBarView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-17.
//

import SwiftUI

struct CircularProgressBar: View {
    var progress: Double            // Progress as a value between 0.0 and 1.0
    var remainingTime: Int          // Countdown value in seconds
    var isResting: Bool = false     // Indicates whether the timer is in rest phase

    // Determine the stroke color based on state and remaining time.
    var strokeColor: Color {
        if isResting {
            return .red
        } else {
            return remainingTime <= 5 ? .yellow : Color.accentColor
        }
    }
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            // Foreground Circle with a solid stroke (based on our computed color)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    strokeColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut, value: progress)
            
            // Center Text Display (formatted to M:SS)
            Text(formatTime(from: remainingTime))
                .font(.system(size: 40, design: .monospaced))
        }
    }
}
