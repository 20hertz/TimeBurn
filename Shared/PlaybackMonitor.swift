//
//  PlaybackMonitor.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-03-11.
//

import Foundation
import AVFoundation

#if os(iOS)
import UIKit
#endif

/// Monitors local audio playback across both iOS and watchOS.
class PlaybackMonitor: ObservableObject {
    @Published var localPlaying: Bool = false
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    
    init() {
        startMonitoring()
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        timer?.invalidate()
    }
    
    func startMonitoring() {
        // Initial check
        checkAndUpdatePlaybackState()
        
        // Set up periodic timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAndUpdatePlaybackState()
        }
        RunLoop.main.add(timer!, forMode: .common)
        
        // Add notification observers for audio session changes
        let interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.checkAndUpdatePlaybackState()
            }
        
        let routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.checkAndUpdatePlaybackState()
            }
        
        observers = [interruptionObserver, routeChangeObserver]
        
        // iOS-specific observers
        #if os(iOS)
        let foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.checkAndUpdatePlaybackState()
            }
            
        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                // Send one final update before going to background
                self?.checkAndUpdatePlaybackState()
            }
        
        observers.append(contentsOf: [foregroundObserver, backgroundObserver])
        #endif
    }
    
    private func checkAndUpdatePlaybackState() {
        let playing = AVAudioSession.sharedInstance().isOtherAudioPlaying
        if playing != self.localPlaying {
            self.localPlaying = playing
            WatchConnectivityProvider.shared.updateLocalMusicPlaybackState(playing: playing)
        }
    }
}
