//
//  SoundPlayer.swift
//  Timer
//
//  Created by Patrick Cunniff on 6/4/23.
//

import AVFoundation
class SoundPlayer {
    var audioPlayer: AVAudioPlayer?
    var volume: Float = 1.0 // Volume property with default value of 1.0
    private var testDelegate: SoundPlayerDelegate?
    
    init() {
        prepareAudioPlayer()
        testDelegate = SoundPlayerDelegate()
    }
    
    func prepareAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "beep", withExtension: "mp3") else {
            print("Warning: Sound file 'beep.mp3' not found in bundle")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to create audio player: \(error)")
        }
    }
    
    func playSound(volume: Int) {
        guard let audioPlayer = audioPlayer else {
            print("Warning: Audio player not available")
            return
        }
        audioPlayer.play()
        audioPlayer.volume = (Float(volume)/100)
    }
    
    func playTestSound(volume: Int) {
        guard let audioPlayer = audioPlayer else {
            print("Warning: Audio player not available")
            return
        }
        audioPlayer.numberOfLoops = 0
        audioPlayer.volume = (Float(volume)/100)
        
        // Utiliser le delegate existant au lieu d'en créer un nouveau
        audioPlayer.delegate = testDelegate
        
        audioPlayer.play()
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
}

class SoundPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Set the number of loops back to -1
        player.numberOfLoops = -1
    }
}
