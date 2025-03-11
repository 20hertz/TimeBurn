//
//  PlaybackMonitor.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-03-11.
//


import Foundation
import AVFoundation

/// Monitors local audio playback across both iOS and watchOS.
class PlaybackMonitor: ObservableObject {
    @Published var localPlaying: Bool = false
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let playing = AVAudioSession.sharedInstance().isOtherAudioPlaying
            if playing != self.localPlaying {
                self.localPlaying = playing
                WatchConnectivityProvider.shared.updateLocalMusicPlaybackState(playing: playing)
            }
        }
    }
}