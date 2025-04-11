//
//  WatchConnectivityProvider.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-04-11.
//

import Foundation
import WatchConnectivity
import AVFoundation

/// iOS-specific implementation of the WatchConnectivityProvider
public class WatchConnectivityProvider: WatchConnectivityProviderBase {
    
    public static let shared = WatchConnectivityProvider()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Override Methods
    
    public override func startSession() {
        super.startSession()
        
        // iOS-specific initialization after session starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Check and update local music playback state
            let audioSession = AVAudioSession.sharedInstance()
            let isPlaying = audioSession.isOtherAudioPlaying
            self.updateLocalMusicPlaybackState(playing: isPlaying)
        }
    }
    
    public override func requestInitialState() {
        // Not needed on iOS since watchOS will request from us
    }
    
    public override func updateLocalMusicPlaybackState(playing: Bool) {
        super.updateLocalMusicPlaybackState(playing: playing)
        
        // iOS-specific key for music playback
        let message: [String: Any] = ["iosMusicPlaying": playing]
        
        // Update application context for background state sync
        updateApplicationContext(message)
        
        // Also send direct message if reachable for immediate update
        if session?.isReachable == true {
            sendMessage(message)
        }
    }
    
    internal override func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        guard let session = session,
              session.isPaired,
              session.isWatchAppInstalled else { return }
        
        session.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    // MARK: - Volume Control
    
    /// Handles volume reduction requests from watchOS
    private func handleVolumeControl(reduce: Bool) {
        // If we're reducing the volume and it's not already reduced
        if reduce && !volumeReduced {
            // Use VolumeControl to handle the actual volume adjustment
            VolumeControl.shared.reduceVolume()
            DispatchQueue.main.async {
                self.volumeReduced = true
            }
        }
        // If we're restoring volume
        else if !reduce && volumeReduced {
            // Use VolumeControl to restore the volume
            VolumeControl.shared.restoreVolume()
            DispatchQueue.main.async {
                self.volumeReduced = false
            }
        }
    }
    
    /// Responds to volume state requests from the watch
    private func respondToVolumeStateRequest(for session: WCSession) {
        let reply: [String: Any] = ["volumeReduced": VolumeControl.shared.isReduced]
        session.sendMessage(reply, replyHandler: nil, errorHandler: nil)
    }
    
    // MARK: - WCSessionDelegate Methods
    
    public override func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // First call the base implementation to handle common functionality
        super.session(session, didReceiveMessage: message)
        
        // Handle iOS-specific message types
        
        // Volume control requests
        if let isVolumeControl = message["volumeControl"] as? Bool, isVolumeControl,
           let reduce = message["reduce"] as? Bool {
            DispatchQueue.main.async {
                self.handleVolumeControl(reduce: reduce)
            }
        }
        
        // Initial state requests
        if let isRequest = message["requestInitialState"] as? Bool, isRequest {
            // Add a small delay to ensure watch is ready to receive
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Send current iOS music playback state
                let audioSession = AVAudioSession.sharedInstance()
                let isPlaying = audioSession.isOtherAudioPlaying
                self.updateLocalMusicPlaybackState(playing: isPlaying)
            }
        }
        
        // Volume state requests
        if let requestState = message["requestVolumeState"] as? Bool, requestState {
            respondToVolumeStateRequest(for: session)
        }
        
        // Watch music playback state updates
        if let watchPlaying = message["watchMusicPlaying"] as? Bool {
            DispatchQueue.main.async {
                self.remoteMusicPlaying = watchPlaying
            }
        }
    }
    
    public override func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Handle music playback updates from the application context
        if let watchPlaying = applicationContext["watchMusicPlaying"] as? Bool {
            DispatchQueue.main.async {
                self.remoteMusicPlaying = watchPlaying
            }
        }
    }
    
    // MARK: - iOS-specific WCSessionDelegate Methods
    
    public override func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    public override func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated, reactivating...")
        session.activate()
    }
}
