//
//  TodoModel.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-08.
//


import Foundation
import Combine

/// A publicly visible model representing a configurable interval timer.
///
/// Conforms to:
/// - `Identifiable`: for use in SwiftUI lists.
/// - `Codable`: for persistence and sending across WatchConnectivity.
/// - `Equatable`: to compare items.
///
/// Only stores permanent, user-defined configuration.
/// Does *not* store runtime state like remaining time or current round.
/// That state lives in memory only (e.g., within TimerEngine).
public struct IntervalTimer: Identifiable, Codable, Equatable, Hashable {
    /// Unique identifier
    public let id: UUID
    
    /// Display name
    public var name: String
    
    /// Duration of the "active" period in seconds
    public var activeDuration: Int
    
    /// Duration of the "rest" period in seconds
    public var restDuration: Int
    
    /// Total number of rounds. If 0, runs indefinitely.
    public var totalRounds: Int
    
    /// Creates a new IntervalTimer.
    public init(
        id: UUID = UUID(),
        name: String,
        activeDuration: Int,
        restDuration: Int,
        totalRounds: Int
    ) {
        self.id = id
        self.name = name
        self.activeDuration = activeDuration
        self.restDuration = restDuration
        self.totalRounds = totalRounds
    }
}
