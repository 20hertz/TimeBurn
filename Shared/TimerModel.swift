//
//  TodoModel.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-08.
//


import Foundation
import Combine

struct Timer: Identifiable, Codable {
    let id: UUID
    var name: String
    var activeDuration: Int
    var restDuration: Int
    var rounds: Int
    var currentRound: Int = 1
    var isRunning: Bool = false
    var remainingTime: Int
    var isActivePeriod: Bool = true
}

class TimerModel: ObservableObject {
    @Published var timers: [Timer] = [] {
        didSet {
            syncWithWatch()
            WatchConnector.shared.timers = timers // Persist timers
        }
    }
    
    init() {
        // Load persisted timers from WatchConnector
        timers = WatchConnector.shared.timers
    }
    
    func addTimer(name: String, activeDuration: Int, restDuration: Int, rounds: Int) {
        let newTimer = Timer(
            id: UUID(),
            name: name,
            activeDuration: activeDuration,
            restDuration: restDuration,
            rounds: rounds,
            remainingTime: activeDuration
        )
        timers.append(newTimer)
    }
    
    func deleteTimer(at offsets: IndexSet) {
        timers.remove(atOffsets: offsets)
    }
    
    private func syncWithWatch() {
        #if os(iOS)
        WatchConnector.shared.send(timers: timers)
        #endif
    }
}
