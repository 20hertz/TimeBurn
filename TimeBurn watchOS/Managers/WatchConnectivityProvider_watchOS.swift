//
//  WatchConnectivityProvider.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-04-11.
//

import Foundation
import WatchConnectivity

/// watchOS-specific implementation of the WatchConnectivityProvider
public class WatchConnectivityProvider: WatchConnectivityProviderBase {
    
    public static let shared = WatchConnectivityProvider()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Override Methods
    
    public override func requestInitialState() {
        guard let session = session, session.isReachable else { return }
        
        let message: [String: Any] = ["requestInitialState": true]
        sendMessage(message)
    }
    
    public override func updateLocalMusicPlaybackState(playing: Bool) {
        super.updateLocalMusicPlaybackState(playing: playing)
        
        // watchOS-specific key for music playback
        let message: [String: Any] = ["watchMusicPlaying": playing]
        
        // Update application context for background state sync
        updateApplicationContext(message)
        
        // Also send direct message if reachable for immediate update
        if session?.isReachable == true {
            sendMessage(message)
        }
    }
    
    internal override func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        guard let session = session, session.isReachable else { return }
        
        session.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    // MARK: - Volume Control
    
    /// Requests the current volume reduction state from iOS
    public func requestVolumeState() {
        guard let session = session, session.isReachable else { return }
        
        let message: [String: Any] = ["requestVolumeState": true]
        
        session.sendMessage(message, replyHandler: { reply in
            if let state = reply["volumeReduced"] as? Bool {
                DispatchQueue.main.async {
                    self.volumeReduced = state
                }
            }
        }, errorHandler: nil)
    }
    
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
        
        sendMessage(message, errorHandler: { error in
            print("Error sending volume control message: \(error)")
        })
    }
    
    // MARK: - WCSessionDelegate Methods
    
    public override func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // First call the base implementation to handle common functionality
        super.session(session, didReceiveMessage: message)
        
        // Handle watchOS-specific message types
        
        // iOS music playback state updates
        if let iosPlaying = message["iosMusicPlaying"] as? Bool {
            DispatchQueue.main.async {
                self.remoteMusicPlaying = iosPlaying
            }
        }
    }
    
    public override func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Handle music playback updates from the application context
        if let iosPlaying = applicationContext["iosMusicPlaying"] as? Bool {
            DispatchQueue.main.async {
                self.remoteMusicPlaying = iosPlaying
            }
        }
    }
}
