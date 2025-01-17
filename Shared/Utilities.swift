//
//  Utilities.swift
//  Gym Time
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
