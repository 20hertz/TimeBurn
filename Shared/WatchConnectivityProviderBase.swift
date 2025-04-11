//
//  WatchConnectivityProvider.swift
//  Timers
//
//  Created by Stéphane on 2025-01-11.
//

import Foundation
import WatchConnectivity
import Combine

/// Base class providing common watch connectivity functionality for both iOS and watchOS.
/// Each platform should implement a specific subclass to handle platform-specific logic.
public class WatchConnectivityProviderBase: NSObject, ObservableObject, WCSessionDelegate {
    
    // MARK: - Properties
    
    /// Access to the shared WCSession
    internal var session: WCSession?
    
    // MARK: - Music Playback State Properties
    
    /// The local device's music playback state
    @Published public var localMusicPlaying: Bool = false
    
    /// The counterpart device's music playback state
    @Published public var remoteMusicPlaying: Bool = false
    
    /// A computed property that is true if either device is playing audio
    public var globalMusicPlaying: Bool {
        return localMusicPlaying || remoteMusicPlaying
    }
    
    /// Volume reduction state
    @Published public var volumeReduced: Bool = false
    
    // MARK: - Initialization
    
    override public init() {
        super.init()
    }
    
    // MARK: - Session Management
    
    /// Starts the watch connectivity session
    public func startSession() {
        guard WCSession.isSupported() else { return }
        
        let defaultSession = WCSession.default
        defaultSession.delegate = self
        defaultSession.activate()
        self.session = defaultSession
        
        // Request initial state after session activation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestInitialState()
        }
    }
    
    /// Requests initial state from the counterpart device
    public func requestInitialState() {
        // To be implemented by subclasses
    }
    
    // MARK: - Timer Synchronization
    
    /// Sends an updated list of IntervalTimers to the counterpart
    public func sendTimers(_ timers: [IntervalTimer]) {
        guard session != nil else { return }
        
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(timers) else { return }
        let message: [String: Any] = ["timers": encoded]
        
        sendMessage(message)
    }
    
    /// Sends a user action (play/pause/reset) for a specific IntervalTimer to the counterpart
    public func sendAction(timerID: UUID, action: TimerAction) {
        guard session != nil else { return }
        
        guard let timer = TimerManager.shared.timers.first(where: { $0.id == timerID }) else {
            return
        }
        
        let engine = ActiveTimerEngines.shared.engine(for: timer)
        
        let payload: [String: Any] = [
            "actionEvent": true,
            "navigateToTimer": timerID.uuidString,
            "timerID": timerID.uuidString,
            "action": action.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "remainingTime": engine.remainingTime,
            "isRestPeriod": (engine.phase == .rest),
            "currentRound": engine.currentRound
        ]
        
        sendMessage(payload)
    }
    
    // MARK: - Music Playback Synchronization
    
    /// Updates the local music playback state and sends it to the counterpart
    public func updateLocalMusicPlaybackState(playing: Bool) {
        DispatchQueue.main.async {
            self.localMusicPlaying = playing
        }
        
        // To be implemented further by subclasses
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to send messages based on platform-specific conditions
    internal func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        // To be implemented by subclasses
    }
    
    /// Updates the application context with a message
    internal func updateApplicationContext(_ message: [String: Any]) {
        do {
            try session?.updateApplicationContext(message)
        } catch {
            print("Error updating application context: \(error)")
        }
    }
    
    // MARK: - Message Handling
    
    /// Processes an action event from the message
    internal func handleActionEvent(_ message: [String: Any]) {
        guard
            let rawAction = message["action"] as? String,
            let action = TimerAction(rawValue: rawAction),
            let timerIDString = message["timerID"] as? String,
            let eventTimestamp = message["timestamp"] as? TimeInterval,
            let remainingTimePayload = message["remainingTime"] as? Int,
            let isRestPayload = message["isRestPeriod"] as? Bool,
            let currentRoundPayload = message["currentRound"] as? Int
        else { return }
        
        let timestampDate = Date(timeIntervalSince1970: eventTimestamp)
        
        DispatchQueue.main.async {
            if let found = TimerManager.shared.timers.first(where: { $0.id.uuidString == timerIDString }) {
                let engine = ActiveTimerEngines.shared.engine(for: found)
                engine.applyAction(
                    action,
                    eventTimestamp: timestampDate,
                    payloadRemainingTime: remainingTimePayload,
                    payloadIsRest: isRestPayload,
                    payloadCurrentRound: currentRoundPayload
                )
            }
        }
    }
    
    /// Handles an incoming navigation request
    internal func handleNavigationRequest(_ timerIDString: String) {
        DispatchQueue.main.async {
            NavigationCoordinator.shared.navigateToTimer(uuidString: timerIDString)
        }
    }
    
    /// Processes timer data from a message
    internal func handleTimerData(_ data: Data) {
        let decoder = JSONDecoder()
        if let updated = try? decoder.decode([IntervalTimer].self, from: data) {
            DispatchQueue.main.async {
                TimerManager.shared.setTimers(updated)
            }
        }
    }
    
    // MARK: - WCSessionDelegate Methods (Common)
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Base implementation to be extended by subclasses
        
        // Handle timer data
        if let data = message["timers"] as? Data {
            handleTimerData(data)
        }
        
        // Handle action events
        if let isActionEvent = message["actionEvent"] as? Bool, isActionEvent {
            handleActionEvent(message)
        }
        
        // Handle navigation requests
        if let timerIDString = message["navigateToTimer"] as? String {
            handleNavigationRequest(timerIDString)
        }
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // To be implemented by subclasses
    }
    
    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        print("WCSession activation completed with state: \(activationState.rawValue)")
        if let error = error {
            print("WCSession activation error: \(error.localizedDescription)")
        }
    }
    
    // These methods only apply to iOS and will be implemented in the iOS subclass
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        // Default implementation - will be overridden by iOS subclass
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        // Default implementation - will be overridden by iOS subclass
    }
    #endif
}
