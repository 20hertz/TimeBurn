//
//  CircularProgressBarView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-17.
//

import SwiftUI

struct CircularProgressBar: View {
    var progress: Double // Progress as a value between 0.0 and 1.0
    var remainingTime: Int // Text to display in the center (e.g. remaining time)

    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            // Foreground Circle with a gradient stroke
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .yellow, .red]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut, value: progress)
            
            // Center Text Display
            Text(formatTime(from: remainingTime))
                .font(.system(size: 30, design: .monospaced))
        }
    }

}

#Preview(traits: .sizeThatFitsLayout) {
    CircularProgressBar(progress: 0.6, remainingTime: 36)
}
