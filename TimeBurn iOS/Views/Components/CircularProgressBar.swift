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
    var color: Color
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            // Foreground Circle
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut, value: progress)
            
            Text(formatTime(from: remainingTime))
                .font(.system(size: 40, design: .monospaced))
        }
    }
}
