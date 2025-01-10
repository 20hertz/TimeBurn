//
//  TimerView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-09.
//

import SwiftUI

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("0:25")
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .padding()

            Text("Round 2 of 5")
                .font(.headline)
                .padding(.bottom)

            Spacer()
        }
        .navigationTitle("Sample Timer")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    TimerView()
}
