//
//  TimerEngine.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-13.
//

import Foundation
import Combine

/// Manages the ephemeral countdown state for an IntervalTimer configuration,
/// handling active/rest transitions, rounds, and synchronization.
public class TimerEngine: ObservableObject {
    
    public enum Phase {
        case idle      // Timer not started or reset.
        case active    // Counting down the active period.
        case rest      // Counting down the rest period.
        case completed // All rounds finished.
    }
    
    // MARK: - Published Properties
    
    /// The underlying configuration.
    @Published public var timer: IntervalTimer
    
    /// The remaining time in the current period (active or rest).
    @Published public var remainingTime: Int
    
    /// Whether the timer is running.
    @Published public var isRunning: Bool = false
    
    /// The current round (1-based).
    @Published public var currentRound: Int = 0
    
    /// The current phase.
    @Published public var phase: Phase = .idle
    
    /// True if the timer has completed all rounds.
    public var isCompleted: Bool { phase == .completed }
    
    // MARK: - Internal Properties
    
    /// DispatchSourceTimer for scheduling ticks.
    private var dispatchTimer: DispatchSourceTimer?
    
    /// Configuration of durations.
    private var activeDuration: Int { timer.activeDuration }
    private var restDuration: Int { timer.restDuration }
    private var totalRounds: Int { timer.totalRounds }
    
    /// The timestamp at which the current period started.
    private var periodStartTime: Date?
    
    /// The total duration (in seconds) for the current period.
    private var periodTotalDuration: Int = 0
    
    /// A cancellable for subscribing to TimerManager updates if desired.
    private var timerManagerSubscription: AnyCancellable?
    
    // MARK: - Initialization
    
    public init(timer: IntervalTimer) {
        self.timer = timer
        self.remainingTime = timer.activeDuration
        self.currentRound = 0
        self.phase = .idle
        subscribeToTimerManager() // Optional: auto-update configuration if TimerManager changes.
    }
    
    // MARK: - Configuration
    
    /// Updates the configuration and resets the engine.
    public func updateConfiguration(to newTimer: IntervalTimer) {
        self.timer = newTimer
        reset()
    }
    
    /// Subscribes to TimerManager’s timers (if you'd like configuration changes to update the engine automatically).
    private func subscribeToTimerManager() {
        timerManagerSubscription = TimerManager.shared.$timers
            .sink { [weak self] timers in
                guard let self = self else { return }
                if let updated = timers.first(where: { $0.id == self.timer.id }) {
                    self.updateConfiguration(to: updated)
                }
            }
    }
    
    // MARK: - Engine Controls
    
    /// Starts or resumes the timer.
    public func play() {
        guard phase != .completed else { return }
        
        if phase == .idle {
            // Fresh start: begin first round of active period.
            currentRound = 1
            phase = .active
            periodTotalDuration = activeDuration
            remainingTime = activeDuration
            periodStartTime = Date()
            #if os(iOS)
            NotificationCenter.default.post(name: .timerPhaseChangedToActive, object: timer)
            #endif
        } else if !isRunning, let _ = periodStartTime {
            // Resuming a paused period (active or rest).
            // Compute the time that had already elapsed before the pause
            let elapsedOnPause = periodTotalDuration - remainingTime
            // Adjust the period start time so that elapsed time computation remains continuous.
            periodStartTime = Date().addingTimeInterval(-TimeInterval(elapsedOnPause))
        }
        
        isRunning = true
        startTimer()
    }
    
    /// Pauses the timer and updates the remaining time based on the absolute elapsed time.
    public func pause() {
        guard isRunning, let start = periodStartTime else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        let newRemaining = periodTotalDuration - elapsed
        remainingTime = max(newRemaining, 0)
        isRunning = false
        cancelTimer()
    }
    
    /// Resets the timer to its initial state.
    public func reset() {
        pause()
        phase = .idle
        currentRound = 0
        remainingTime = activeDuration
        periodStartTime = nil
    }
    
    // MARK: - Timer Scheduling
    
    /// Starts the DispatchSourceTimer to update every second.
    private func startTimer() {
        cancelTimer()
        dispatchTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        dispatchTimer?.schedule(deadline: .now(), repeating: 0.2)
        dispatchTimer?.setEventHandler { [weak self] in
            self?.tick()
        }
        dispatchTimer?.resume()
    }
    
    /// Cancels the dispatch timer if it exists.
    private func cancelTimer() {
        dispatchTimer?.cancel()
        dispatchTimer = nil
    }
    
    // MARK: - Tick Logic
    
    /// Computes elapsed time using the stored periodStartTime and updates remainingTime.
    private func tick() {
        guard isRunning, let start = periodStartTime else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        let newRemaining = periodTotalDuration - elapsed
        remainingTime = max(newRemaining, 0)
        
        if remainingTime == 0 {
            advancePeriod()
        }
    }
    
    /// Handles transitions between active, rest, and completion.
    private func advancePeriod() {
        // We only post "timerActivePhaseEnded" if we are about to go to rest
        // OR if this is the final active round.
        if phase == .active {
            let isLastActiveRound = (totalRounds != 0 && currentRound == totalRounds)
            
            #if os(iOS)
            // Post 3-rings if either this is the last round OR restDuration > 0
            if isLastActiveRound || restDuration > 0 {
                NotificationCenter.default.post(name: .timerActivePhaseEnded, object: timer)
            }
            #endif
            
            // Now handle what happens after finishing this active period:
            if isLastActiveRound {
                // All done
                phase = .completed
                isRunning = false
                remainingTime = 0
                cancelTimer()
                return
            }
            
            // If there's a rest interval, go to rest phase
            if restDuration > 0 {
                phase = .rest
                periodTotalDuration = restDuration
                remainingTime = restDuration
                periodStartTime = Date()
            } else {
                // If restDuration == 0, skip rest entirely and jump to the next round
                nextRound()
            }
            
        } else if phase == .rest {
            // After a rest period ends, we start the next active round
            nextRound()
        }
    }
    
    /// Advances to the next round of active timing.
    private func nextRound() {
        if totalRounds == 0 || currentRound < totalRounds {
            currentRound += 1
            phase = .active
            periodTotalDuration = activeDuration
            remainingTime = activeDuration
            periodStartTime = Date()
            #if os(iOS)
            NotificationCenter.default.post(name: .timerPhaseChangedToActive, object: timer)
            #endif
        } else {
            phase = .completed
            isRunning = false
            remainingTime = 0
            cancelTimer()
        }
    }
    
    // MARK: - Timestamp-Based Adjustments

    /// Applies an action (play, pause, reset) received via synchronization.
    /// The payload carries the sender’s snapshot (remainingTime, isRestPeriod, currentRound)
    /// and an absolute event timestamp.
    /// The receiver uses these values to update its state and adjusts its periodStartTime
    /// to account for any transmission delay.
    public func applyAction(
        _ action: TimerAction,
        eventTimestamp: Date,
        payloadRemainingTime: Int,
        payloadIsRest: Bool,
        payloadCurrentRound: Int
    ) {
        // Override the local state with the sender’s snapshot.
        remainingTime = payloadRemainingTime
        currentRound = payloadCurrentRound
        periodTotalDuration = payloadIsRest ? timer.restDuration : timer.activeDuration
        
        // Compute the raw offset
        let rawOffset = Date().timeIntervalSince(eventTimestamp)

        // Adjust the offset by subtracting 1 second. Ensure it doesn't go negative.
        let adjustedOffset = max(rawOffset - 1, 0)

        // Then, calculate the elapsed time (senderElapsed) as before:
        let senderElapsed = Double(periodTotalDuration - payloadRemainingTime)

        // And combine with the adjusted offset:
        let elapsedWhenPaused = senderElapsed + adjustedOffset

        // Finally, update periodStartTime accordingly:
        periodStartTime = Date().addingTimeInterval(-elapsedWhenPaused)
        
        // Perform the requested action.
        switch action {
            case .play:
                ActiveTimerEngines.shared.resetAnyRunningTimers(except: timer.id)
                play()
            case .pause:
                pause()
            case .reset:
                reset()
        }
    }
}
