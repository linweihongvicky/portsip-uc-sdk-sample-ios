import AVFoundation

// private implementation
//
class SoundService {
    var playerRingBackTone: AVAudioPlayer!
    var playerRingTone: AVAudioPlayer!
    var speakerOn: Bool!

    func initPlayerWithPath(_ path: String) -> AVAudioPlayer {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: path, ofType: nil)!)

        var player: AVAudioPlayer!
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch {}

        return player
    }

    func unInit() {
        if playerRingBackTone != nil {
            if playerRingBackTone.isPlaying {
                playerRingBackTone.stop()
            }
        }

        if playerRingTone != nil {
            if playerRingTone.isPlaying {
                playerRingTone.stop()
            }
        }
    }

    //
    // SoundService
    //
    func speakerEnabled(_ enabled: Bool) {
        let session = AVAudioSession.sharedInstance()
        var options = session.categoryOptions

        if enabled {
            options.insert(AVAudioSession.CategoryOptions.defaultToSpeaker)
        } else {
            options.remove(AVAudioSession.CategoryOptions.defaultToSpeaker)
        }
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: options)
            NSLog("Playback OK")
        } catch {
            NSLog("ERROR: CANNOT speakerEnabled. Message from code: \"\(error)\"")
        }
        
        
    }

    func isSpeakerEnabled() -> Bool {
        speakerOn
    }

    func playRingTone() -> Bool {
        if playerRingTone == nil {
            playerRingTone = initPlayerWithPath("ringtone.mp3")
        }
        if playerRingTone != nil {
            playerRingTone.numberOfLoops = -1
            speakerEnabled(true)
            playerRingTone.play()
            return true
        }
        return false
    }

    func stopRingTone() -> Bool {
        if playerRingTone != nil, playerRingTone.isPlaying {
            playerRingTone.stop()
            speakerEnabled(true)
        }
        return true
    }

    func playRingBackTone() -> Bool {
        if playerRingBackTone == nil {
            playerRingBackTone = initPlayerWithPath("ringtone.mp3")
        }
        if playerRingBackTone != nil {
            playerRingBackTone.numberOfLoops = -1
            speakerEnabled(false)
            playerRingBackTone.play()
            return true
        }

        return false
    }

    func stopRingBackTone() -> Bool {
        if playerRingBackTone != nil, playerRingBackTone.isPlaying {
            playerRingBackTone.stop()
            speakerEnabled(true)
        }
        return true
    }
}
