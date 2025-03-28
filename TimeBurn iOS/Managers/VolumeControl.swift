//
//  VolumeControl.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-03-28.
//

import Foundation
import MediaPlayer
import AVFoundation

/// Manages system volume control for the TimeBurn app
class VolumeControl {
    static let shared = VolumeControl()
    
    // The original volume level before reduction
    private var originalVolume: Float = 1.0
    
    // Current state of volume reduction
    private(set) var isReduced: Bool = false
    
    // The MPVolumeView we use to control volume
    private var volumeView: MPVolumeView?
    
    private init() {
        createVolumeView()
    }
    
    private func createVolumeView() {
        let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        
        // Add to a window (required for functionality)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(volumeView)
            self.volumeView = volumeView
        }
    }
    
    /// Gets the volume slider from MPVolumeView
    private func getVolumeSlider() -> UISlider? {
        return volumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider
    }
    
    /// Reduces the volume by 50%
    func reduceVolume() {
        // Get current system volume
        let audioSession = AVAudioSession.sharedInstance()
        let currentVolume = audioSession.outputVolume
        
        // Store original volume for later restoration
        self.originalVolume = currentVolume
        
        // Calculate target volume (half of current)
        let halfVolume = currentVolume * 0.4
        print("REDUCING volume from \(currentVolume) to \(halfVolume)")
        
        // Set the volume to half
        if let slider = getVolumeSlider() {
            slider.value = halfVolume
        }
        
        isReduced = true
    }
    
    /// Restores the volume to original level
    func restoreVolume() {
        print("RESTORING volume to \(originalVolume)")
        
        if let slider = getVolumeSlider() {
            slider.value = originalVolume
        }
        
        isReduced = false
    }
    
    /// Toggles the volume reduction on/off
    func toggleVolumeReduction() {
        if isReduced {
            restoreVolume()
        } else {
            reduceVolume()
        }
    }
}
