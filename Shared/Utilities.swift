//
//  Utilities.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-17.
//

import Foundation

/// Format time into `mm:ss`.
func formatTime(from seconds: Int) -> String {
    let minutes = seconds / 60
    let secs = seconds % 60
    return String(format: "%d:%02d", minutes, secs)
}

// In Utilities.swift or another shared file
extension IntervalTimer {
    var configurationText: String {
        let roundsText = (self.totalRounds == 0 ? "∞" : "\(self.totalRounds)")
        let activeText = formatTime(from: self.activeDuration)
        var config = "\(roundsText) × \(activeText)"
        // Only include rest duration if more than 1 round and restDuration is greater than 0.
        if self.totalRounds != 1 && self.restDuration > 0 {
            let restText = formatTime(from: self.restDuration)
            config += " | \(restText)"
        }
        return config
    }
}
