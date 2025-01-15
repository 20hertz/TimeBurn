//
//  TimerEngine.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-13.
//

import Foundation
import Combine
/// Manages the runtime state of a single `IntervalTimer` (e.g., countdown, round transitions),
/// including a local 1-second ticker. Does *not* persist ephemeral state.
///
/// Only one TimerEngine should run at a time, but you can create multiple
/// to handle different timers sequentially.
public class TimerEngine: ObservableObject {
    
    /// Represents the current phase of the interval timer.
    public enum Phase {
        case idle  // Timer not started or is reset
        case active
        case rest
        case completed  // All rounds finished
    }
    
    /// The underlying IntervalTimer configuration (persisted data).
    public let timer: IntervalTimer
    
    /// Current round (1-based). If totalRounds == 0 => indefinite.
    @Published public private(set) var currentRound: Int = 0
    
    /// Remaining seconds in the current phase.
    @Published public private(set) var remainingSeconds: Int = 0
    
    /// The current phase (idle, active, rest, or completed).
    @Published public private(set) var phase: Phase = .idle
    
    /// Simple state to track if we're running or paused.
    @Published public private(set) var isRunning: Bool = false
    
    /// Internal 1-second timer subscription.
    private var timerSubscription: Cancellable?
    
    // MARK: - Initialization
    
    public init(timer: IntervalTimer) {
        self.timer = timer
        self.remainingSeconds = timer.activeDuration
    }
    
    // MARK: - Engine Controls
    
    /// Starts the timer from the current phase and remaining time.
    /// If idle, initialize round=1 and load `activeDuration`.
    public func play() {
        guard phase != .completed else { return }
        
        if phase == .idle {
            currentRound = 1
            phase = .active
            remainingSeconds = timer.activeDuration
        }
        
        isRunning = true
        startTicking()
    }
    
    /// Pauses the countdown.
    public func pause() {
        isRunning = false
        timerSubscription?.cancel()
    }
    
    /// Resets the entire timer to the idle phase.
    public func reset() {
        pause()
        currentRound = 1
        remainingSeconds = timer.activeDuration
        phase = .idle
    }
    
    /// Advances the engine by 1 second at a time.
    private func startTicking() {
        // Cancel any existing subscription
        timerSubscription?.cancel()
        
        timerSubscription = Timer
            .publish(every: 1.0, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    /// Decrements the remaining time, handles transitions between active/rest,
    /// handles round increments, and checks for completion.
    private func tick() {
        guard isRunning else { return }
        
        // If no time left, transition
        if remainingSeconds <= 0 {
            switch phase {
            case .active:
                // Completed an active phase
                if timer.restDuration > 0 {
                    phase = .rest
                    remainingSeconds = timer.restDuration
                } else {
                    self.handleRoundCompletion()
                }
                
            case .rest:
                // Completed a rest phase => next round
                self.handleRoundCompletion()
                
            default:
                break
            }
        } else {
            // Decrement
            remainingSeconds -= 1
        }
    }
    
    /// Called when finishing either an active or rest phase.
    private func handleRoundCompletion() {
        // If indefinite or have more rounds left
        if timer.totalRounds == 0 || currentRound < timer.totalRounds {
            // Move to next round
            if phase == .rest {
                currentRound += 1
                phase = .active
                remainingSeconds = timer.activeDuration
            } else {
                // If we directly come here from active with no rest
                currentRound += 1
                if timer.restDuration > 0 {
                    phase = .rest
                    remainingSeconds = timer.restDuration
                } else {
                    // Edge case: no rest
                    phase = .active
                    remainingSeconds = timer.activeDuration
                }
            }
        } else {
            // Completed final round
            phase = .completed
            isRunning = false
            timerSubscription?.cancel()
        }
    }
    
    // MARK: - Timestamp-Based Adjustments
    
    /// Applies an action (play/pause/reset) that happened at a given `eventTimestamp`.
    /// Offsets local state if there's any delay.
    public func applyAction(
        _ action: TimerAction,
        eventTimestamp: Date
    ) {
        let now = Date()
        let offset = now.timeIntervalSince(eventTimestamp)
        
        switch action {
        case .play:
            // Possibly reduce remainingSeconds by the offset (i.e., if the other device has been running).
            if phase == .active || phase == .rest {
                let offsetInt = Int(offset)
                remainingSeconds = max(0, remainingSeconds - offsetInt)
            }
            play()
        case .pause:
            // If we were running for offset seconds after the event
            if isRunning {
                let offsetInt = Int(offset)
                remainingSeconds = max(0, remainingSeconds - offsetInt)
            }
            pause()
        case .reset:
            reset()
        }
    }
}
