//
//  AudioManager.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-01-24.
//

import Foundation
import AVFoundation

/// Manages audio playback for the TimeBurn app on iOS.
class AudioManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private override init() {
        super.init()
        
        // Observe for notifications to play sounds.
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
    
    /// Plays the specified sound and automatically deactivates the audio session afterward.
    /// - Parameters:
    ///   - soundName: The name of the sound file (without extension).
    ///   - soundExtension: The extension of the sound file.
    func playSound(soundName: String, soundExtension: String = "aac") {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: soundExtension) else {
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            // Activate the session with ducking and notifyOthersOnDeactivation options.
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing sound '\(soundName).\(soundExtension)': \(error.localizedDescription)")
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Deactivate the audio session to restore other audio's volume.
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handlePhaseChangeToActiveNotification(_ notification: Notification) {
        if let timer = notification.object as? IntervalTimer, timer.enableSound {
            playSound(soundName: "Bell - 1 Ring")
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
