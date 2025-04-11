//
//  WatchConnectivityProvider.swift
//  Timers
//
//  Created by Stéphane on 2025-01-11.
//

import Foundation
import WatchConnectivity
import Combine
import AVFoundation

/// A unified provider for watch connectivity, used by both iOS and watchOS.
/// Handles syncing of IntervalTimer lists, user actions (play/pause/reset), and now music playback state.
public class WatchConnectivityProvider: NSObject, ObservableObject, WCSessionDelegate {
    
    public static let shared = WatchConnectivityProvider()
    
    private override init() {}
    
    private var session: WCSession?
    
    // MARK: - Music Playback State Properties
    
    /// The local device's music playback state.
    @Published public var localMusicPlaying: Bool = false
    
    /// The counterpart device's music playback state.
    @Published public var remoteMusicPlaying: Bool = false
    
    /// A computed state that is true if either device is playing audio.
    public var globalMusicPlaying: Bool {
        return localMusicPlaying || remoteMusicPlaying
    }
    
    // MARK: - Volume Control
    
    #if os(iOS)
    /// Store the original volume before reduction
    private var originalVolume: Float = 1.0
    
    /// The current state of volume reduction
    @Published public var volumeReduced: Bool = false
    #endif
    
    // MARK: - Session Setup
    
    /// Starts the watch connectivity session.
    public func startSession() {
        guard WCSession.isSupported() else { return }
        let defaultSession = WCSession.default
        defaultSession.delegate = self
        defaultSession.activate()
        self.session = defaultSession
        
        // Request initial state after session activation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestInitialState()
            
            // Also, on iOS, check and update the local music state
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            let isPlaying = audioSession.isOtherAudioPlaying
            self.updateLocalMusicPlaybackState(playing: isPlaying)
            #endif
        }
    }
    
    public func requestInitialState() {
        #if os(watchOS)
        guard let session = session, session.isReachable else { return }
        let message: [String: Any] = ["requestInitialState": true]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        #endif
    }
    
    // MARK: - Timer and Action Methods (unchanged)
    
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
    
    /// Sends a user action (play/pause/reset) for a specific IntervalTimer to the counterpart.
    public func sendAction(timerID: UUID, action: TimerAction) {
        guard let session = session else { return }
        
        let engine = ActiveTimerEngines.shared.engine(for: TimerManager.shared.timers.first { $0.id == timerID }!)
        
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
        
        #if os(iOS)
        guard session.isPaired, session.isWatchAppInstalled else { return }
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        
        #elseif os(watchOS)
        guard session.isReachable else { return }
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        #endif
    }
    
    // MARK: - Volume Control Methods
    
    #if os(watchOS)
    /// Sends a command to the iPhone to reduce or restore volume
    public func sendVolumeControl(reduce: Bool) {
        guard let session = session, session.isReachable else { return }
        
        // Update our local state immediately
        DispatchQueue.main.async {
            self.volumeReduced = reduce
        }
        
        let message: [String: Any] = [
            "volumeControl": true,
            "reduce": reduce
        ]
        
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("Error sending volume control message: \(error)")
        })
    }
    
    @Published public var volumeReduced: Bool = false

    public func requestVolumeState() {
        guard let session = session, session.isReachable else { return }
        
        let message: [String: Any] = [
            "requestVolumeState": true
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            if let state = reply["volumeReduced"] as? Bool {
                DispatchQueue.main.async {
                    self.volumeReduced = state
                }
            }
        }, errorHandler: nil)
    }
    #endif
    
    #if os(iOS)
    /// Handles volume reduction requests from watchOS
    private func handleVolumeControl(reduce: Bool) {
        // If we're reducing the volume and it's not already reduced
        if reduce && !volumeReduced {
            // Use VolumeControl to handle the actual volume adjustment
            VolumeControl.shared.reduceVolume()
            volumeReduced = true
        }
        // If we're restoring volume
        else if !reduce && volumeReduced {
            // Use VolumeControl to restore the volume
            VolumeControl.shared.restoreVolume()
            volumeReduced = false
        }
    }
    #endif
    
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
                    payloadCurrentRound: currentRoundPayload
                )
            }
        }
    }
    
    // MARK: - Music Playback State Methods
    
    /// Updates the local music playback state and sends it to the counterpart.
    public func updateLocalMusicPlaybackState(playing: Bool) {
        DispatchQueue.main.async {
            self.localMusicPlaying = playing
        }
        
        // Determine the correct key based on platform
        #if os(iOS)
        let key = "iosMusicPlaying"
        #else
        let key = "watchMusicPlaying"
        #endif
        
        let message: [String: Any] = [key: playing]
        
        // Update application context for background state sync
        do {
            try session?.updateApplicationContext(message)
        } catch {
            print("Error updating music playback context: \(error)")
        }
        
        // Also send direct message if reachable for immediate update
        if session?.isReachable == true {
            session?.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
    
    /// Sends the local music playback state using the specified key.
    private func sendMusicPlaybackState(key: String, playing: Bool) {
        let message: [String: Any] = [key: playing]
        // Update application context for background state sync.
        do {
            try session?.updateApplicationContext(message)
        } catch {
            print("Error updating music playback context: \(error)")
        }
        // Send immediate message if reachable.
        if session?.isReachable == true {
            session?.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("Error sending music playback message: \(error)")
            })
        }
    }
    
    // MARK: - WCSessionDelegate Methods
    
    /// Called when a message arrives. We check for timers, action events, navigation events, music playback updates, or volume control.
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
        
        // 3) Incoming navigation event
        if let timerIDString = message["navigateToTimer"] as? String {
            DispatchQueue.main.async {
                NavigationCoordinator.shared.navigateToTimer(uuidString: timerIDString)
            }
        }
        
        // 4) Incoming volume control event
        #if os(iOS)
        if let isVolumeControl = message["volumeControl"] as? Bool, isVolumeControl,
           let reduce = message["reduce"] as? Bool {
            DispatchQueue.main.async {
                self.handleVolumeControl(reduce: reduce)
            }
        }
        
        if let isRequest = message["requestInitialState"] as? Bool, isRequest {
            // Add a small delay to ensure watch is ready to receive
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Send current iOS music playback state
                let audioSession = AVAudioSession.sharedInstance()
                let isPlaying = audioSession.isOtherAudioPlaying
                self.updateLocalMusicPlaybackState(playing: isPlaying)
            }
        }
        
        if let requestState = message["requestVolumeState"] as? Bool, requestState {
            session.sendMessage(["volumeReduced": VolumeControl.shared.isReduced], replyHandler: nil, errorHandler: nil)
        }
        #endif
        
        // 5) Incoming music playback updates
        #if os(iOS)
        // On iOS, update remote state from the watch.
        if let watchPlaying = message["watchMusicPlaying"] as? Bool {
            DispatchQueue.main.async {
                self.remoteMusicPlaying = watchPlaying
            }
        }
        #elseif os(watchOS)
        // On watchOS, update remote state from the iOS device.
        if let iosPlaying = message["iosMusicPlaying"] as? Bool {
            DispatchQueue.main.async {
                self.remoteMusicPlaying = iosPlaying
            }
        }
        #endif
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Handle music playback updates from the application context.
        #if os(iOS)
        if let watchPlaying = applicationContext["watchMusicPlaying"] as? Bool {
            DispatchQueue.main.async {
                self.remoteMusicPlaying = watchPlaying
            }
        }
        #elseif os(watchOS)
        if let iosPlaying = applicationContext["iosMusicPlaying"] as? Bool {
            DispatchQueue.main.async {
                self.remoteMusicPlaying = iosPlaying
            }
        }
        #endif
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
