import Foundation

protocol ProgressionPlaying: AnyObject {
    var isPlaying: Bool { get }
    func play(chords: [PlaybackChord], bpm: Double)
    func stop()
}

extension ProgressionAudioPlayer: ProgressionPlaying {}
