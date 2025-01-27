//
//  AudioManager.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-24.
//

import Foundation
import AVFoundation

/// Manages audio playback for the Gym Time app on iOS.
class AudioManager {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        // Observe for notifications to play sounds
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePhaseChangeToRestNotification(_:)),
            name: .timerPhaseChangedToRest,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePhaseChangeToActiveNotification(_:)),
            name: .timerPhaseChangedToActive,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Plays the specified sound.
    /// - Parameters:
    ///   - soundName: The name of the sound file (without extension).
    ///   - soundExtension: The extension of the sound file.
    ///   - volume: The volume at which to play the sound (0.0 to 1.0). Default is 1.0.
    func playSound(soundName: String, soundExtension: String = "aac", volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: soundExtension) else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing sound '\(soundName).\(soundExtension)': \(error.localizedDescription)")
        }
    }
    
    /// Handles phase change to rest notifications.
    @objc private func handlePhaseChangeToRestNotification(_ notification: Notification) {
        if let timer = notification.object as? IntervalTimer {
            if timer.enableSound {
                playSound(soundName: "Bell - 3 Rings")
            }
        }
    }
    
    /// Handles phase change to active notifications.
    @objc private func handlePhaseChangeToActiveNotification(_ notification: Notification) {
        if let timer = notification.object as? IntervalTimer {
            if timer.enableSound {
                playSound(soundName: "Bell - 1 Ring")
            }
        }
    }
}

extension Notification.Name {
    /// Notification posted when the timer phase changes to rest.
    static let timerPhaseChangedToRest = Notification.Name("timerPhaseChangedToRest")
    
    /// Notification posted when a new round starts (phase changes to active).
    static let timerPhaseChangedToActive = Notification.Name("timerPhaseChangedToActive")
}
