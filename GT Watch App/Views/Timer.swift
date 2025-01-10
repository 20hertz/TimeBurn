//
//  TimerView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-09.
//

import SwiftUI

struct TimerView: View {
    let timer: Timer

    var body: some View {
        VStack {
            Text("\(timer.remainingTime / 60):\(String(format: "%02d", timer.remainingTime % 60))")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .padding()

            Text("Round \(timer.currentRound) of \(timer.rounds)")
                .font(.subheadline)
                .padding(.bottom)

            Spacer()
        }
        .navigationTitle(timer.name)
    }
}

#Preview {
    TimerView(
        timer: Timer(
            id: UUID(),
            name: "Sample Timer",
            activeDuration: 30,
            restDuration: 10,
            rounds: 5,
            remainingTime: 25
        )
    )
}
