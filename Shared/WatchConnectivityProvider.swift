//
//  WatchConnectivityProvider.swift
//  Timers
//
//  Created by Stéphane on 2025-01-11.
//

import Foundation
import WatchConnectivity
import Combine

/// A unified provider for watch connectivity, used by both iOS and watchOS.
/// Handles syncing of IntervalTimer lists and user actions (play/pause/reset).
public class WatchConnectivityProvider: NSObject, ObservableObject, WCSessionDelegate {
    
    public static let shared = WatchConnectivityProvider()
    
    private override init() {}
    
    private var session: WCSession?
    
    /// Starts the watch connectivity session.
    public func startSession() {
        guard WCSession.isSupported() else { return }
        let defaultSession = WCSession.default
        defaultSession.delegate = self
        defaultSession.activate()
        self.session = defaultSession
    }
    
    // MARK: - Send/Receive Full Timer Lists
    
    /// Sends an updated list of IntervalTimers to the counterpart.
    public func sendTimers(_ timers: [IntervalTimer]) {
        guard let session = session else { return }
        
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(timers) else { return }
        let message: [String: Any] = ["timers": encoded]
        
        #if os(iOS)
        guard session.isPaired, session.isWatchAppInstalled else { return }
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        
        #elseif os(watchOS)
        guard session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        #endif
    }
    
    // MARK: - Send/Receive User Actions
    
    /// Sends a user action (play/pause/reset) for a specific IntervalTimer to the counterpart.
    public func sendAction(timerID: UUID, action: TimerAction) {
        guard let session = session else { return }
        
        // Here we assume that TimerManager.shared or the currently active engine
        // has the snapshot we want to send. Adjust as needed if you have a different source.
        let engine = ActiveTimerEngines.shared.engine(for: TimerManager.shared.timers.first { $0.id == timerID }!)
        
        let payload: [String: Any] = [
            "actionEvent": true,
            "timerID": timerID.uuidString,
            "action": action.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "remainingTime": engine.remainingTime,
            "isRestPeriod": (engine.phase == .rest),
            "currentRound": engine.currentRound
        ]
        
        #if os(iOS)
        guard session.isPaired, session.isWatchAppInstalled else { return }
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        
        #elseif os(watchOS)
        guard session.isReachable else { return }
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        #endif
    }
    
    private func handleActionEvent(_ message: [String : Any]) {
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
                    payloadCurrentRound: currentRoundPayload)
            }
        }
    }
    
    // MARK: - WCSessionDelegate
    
    /// Called when a message arrives. We check if it's an timers array or an action event.
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // 1) Incoming timers
        if let data = message["timers"] as? Data {
            let decoder = JSONDecoder()
            if let updated = try? decoder.decode([IntervalTimer].self, from: data) {
                DispatchQueue.main.async {
                    TimerManager.shared.setTimers(updated)
                }
            }
        }
        
        // 2) Incoming action event
        if let isActionEvent = message["actionEvent"] as? Bool, isActionEvent {
            handleActionEvent(message)
        }
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}
}
