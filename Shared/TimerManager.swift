//
//  TimerManager.swift
//  Timers
//
//  Created by Stéphane on 2025-01-11.
//

import Foundation
import Combine

/// Represents a user action on a timer that must be synchronized.
public enum TimerAction: String, Codable {
    case play
    case pause
    case reset
}

/// Stores and manages a list of `IntervalTimer` configurations using App Groups.
/// Does *not* store ephemeral countdown state. For that, use `TimerEngine`.
public class TimerManager: ObservableObject {
    public static let shared = TimerManager()
    
    @Published public private(set) var timers: [IntervalTimer] = []
    
    private let suiteName = "group.com.slo.Gym-Time"
    
    private init() {
        loadTimers()
    }
    
    // MARK: - CRUD
    public func addTimer(
        name: String,
        activeDuration: Int,
        restDuration: Int,
        totalRounds: Int
    ) {
        let newInterval = IntervalTimer(
            name: name,
            activeDuration: activeDuration,
            restDuration: restDuration,
            totalRounds: totalRounds
        )
        timers.append(newInterval)
        saveTimers()
    }
    
    public func deleteTimer(_ interval: IntervalTimer) {
        timers.removeAll { $0.id == interval.id }
        saveTimers()
    }
    
    public func updateTimer(
        _ interval: IntervalTimer,
        name: String? = nil,
        activeDuration: Int? = nil,
        restDuration: Int? = nil,
        totalRounds: Int? = nil
    ) {
        guard let idx = timers.firstIndex(of: interval) else { return }
        if let name = name {
            timers[idx].name = name
        }
        if let a = activeDuration {
            timers[idx].activeDuration = a
        }
        if let r = restDuration {
            timers[idx].restDuration = r
        }
        if let t = totalRounds {
            timers[idx].totalRounds = t
        }
        saveTimers()
    }
    
    public func setTimers(_ newList: [IntervalTimer]) {
        timers = newList
        saveTimers()
    }
    
    // MARK: - Persistence
    
    private func saveTimers() {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName) else { return }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(timers) {
            sharedDefaults.set(data, forKey: "savedIntervals")
        }
    }
    
    private func loadTimers() {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName) else { return }
        if let data = sharedDefaults.data(forKey: "savedIntervals"),
           let decoded = try? JSONDecoder().decode([IntervalTimer].self, from: data) {
            timers = decoded
        } else {
            timers = []
        }
    }
}
