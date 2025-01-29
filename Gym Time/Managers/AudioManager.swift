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
            selector: #selector(handlePhaseChangeToActiveNotification(_:)),
            name: .timerPhaseChangedToActive,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivePhaseEnded(_:)),
            name: .timerActivePhaseEnded,
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
    
    @objc private func handlePhaseChangeToActiveNotification(_ notification: Notification) {
        if let timer = notification.object as? IntervalTimer {
            if timer.enableSound {
                playSound(soundName: "Bell - 1 Ring")
            }
        }
    }
    
    @objc private func handleActivePhaseEnded(_ notification: Notification) {
        guard let timer = notification.object as? IntervalTimer else { return }
        if timer.enableSound {
            playSound(soundName: "Bell - 3 Rings")
        }
    }
}

extension Notification.Name {
    /// Notification posted when a new round starts (phase changes to active).
    static let timerPhaseChangedToActive = Notification.Name("timerPhaseChangedToActive")
    
    /// Notification posted when the active phase ends.
    static let timerActivePhaseEnded = Notification.Name("timerActivePhaseEnded")
}
