import AVFoundation
import Combine
import Foundation

struct PlaybackChord {
    let rootPitchClass: Int
    let intervals: [Int]
}

final class ProgressionAudioPlayer: ObservableObject {
    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private var playbackID = UUID()

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play(chords: [PlaybackChord]) {
        guard !chords.isEmpty else { return }

        if isPlaying {
            stop()
            return
        }

        let id = UUID()
        playbackID = id
        configureAudioSession()

        let chordDuration = 1.25
        let buffer = makeBuffer(chords: chords, chordDuration: chordDuration)
        let totalDuration = chordDuration * Double(chords.count)

        player.stop()
        if !engine.isRunning {
            try? engine.start()
        }

        player.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
            DispatchQueue.main.async {
                guard self?.playbackID == id else { return }
                self?.isPlaying = false
            }
        }

        isPlaying = true
        player.play()

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.08) { [weak self] in
            guard self?.playbackID == id else { return }
            self?.isPlaying = false
        }
    }

    func stop() {
        playbackID = UUID()
        player.stop()
        isPlaying = false
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }

    private func makeBuffer(chords: [PlaybackChord], chordDuration: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount((Double(chords.count) * chordDuration * sampleRate).rounded(.up))
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let samples = buffer.floatChannelData?[0] else { return buffer }
        for frame in 0..<Int(frameCount) {
            samples[frame] = 0
        }

        let voicedChords = makeVoicedChords(from: chords)
        for (chordIndex, midiNotes) in voicedChords.enumerated() {
            let chordStart = Double(chordIndex) * chordDuration
            renderChord(midiNotes: midiNotes, startTime: chordStart, duration: chordDuration * 0.94, into: samples, frameCount: Int(frameCount))
        }

        return buffer
    }

    private func makeVoicedChords(from chords: [PlaybackChord]) -> [[Int]] {
        var result: [[Int]] = []

        for chord in chords {
            let candidates = voicingCandidates(for: chord)
            guard !candidates.isEmpty else { continue }

            let selected: [Int]
            if let previous = result.last {
                selected = candidates.min { score(candidate: $0, after: previous) < score(candidate: $1, after: previous) } ?? candidates[0]
            } else {
                selected = candidates.min { openingScore($0) < openingScore($1) } ?? candidates[0]
            }
            result.append(selected)
        }

        return result
    }

    private func voicingCandidates(for chord: PlaybackChord) -> [[Int]] {
        let pitchClasses = uniquePitchClasses(for: chord)
        let choices = pitchClasses.map { pitchClass in
            stride(from: 40, through: 76, by: 1).filter { $0 % 12 == pitchClass }
        }

        var candidates: [[Int]] = [[]]
        for choice in choices {
            candidates = candidates.flatMap { partial in
                choice.map { (partial + [$0]).sorted() }
            }
        }

        return candidates
            .filter { Set($0).count == pitchClasses.count }
            .filter { notes in
                guard let first = notes.first, let last = notes.last else { return false }
                return last - first <= 16
            }
    }

    private func uniquePitchClasses(for chord: PlaybackChord) -> [Int] {
        var seen: Set<Int> = []
        var result: [Int] = []
        for interval in chord.intervals {
            let pitchClass = (chord.rootPitchClass + interval + 120) % 12
            if !seen.contains(pitchClass) {
                seen.insert(pitchClass)
                result.append(pitchClass)
            }
        }
        return result
    }

    private func openingScore(_ candidate: [Int]) -> Double {
        abs(average(candidate) - 55) + span(candidate) * 0.12
    }

    private func score(candidate: [Int], after previous: [Int]) -> Double {
        let movement = zip(candidate, previous).reduce(0) { total, pair in
            total + abs(pair.0 - pair.1)
        }
        let averageShift = abs(average(candidate) - average(previous))
        return Double(movement) + averageShift * 0.8 + span(candidate) * 0.08
    }

    private func average(_ notes: [Int]) -> Double {
        guard !notes.isEmpty else { return 0 }
        return Double(notes.reduce(0, +)) / Double(notes.count)
    }

    private func span(_ notes: [Int]) -> Double {
        guard let first = notes.first, let last = notes.last else { return 0 }
        return Double(last - first)
    }

    private func renderChord(midiNotes: [Int], startTime: Double, duration: Double, into samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        let strumDelay = 0.075
        let amplitude = min(0.18, 0.48 / Double(max(midiNotes.count, 1)))

        for (toneIndex, midiNote) in midiNotes.enumerated() {
            let noteStart = startTime + Double(toneIndex) * strumDelay
            let noteDuration = max(0.12, duration - Double(toneIndex) * strumDelay)
            let frequency = frequency(forMidiNote: midiNote)
            let startFrame = max(0, Int(noteStart * sampleRate))
            let endFrame = min(frameCount, startFrame + Int(noteDuration * sampleRate))
            guard startFrame < endFrame else { continue }

            for frame in startFrame..<endFrame {
                let time = Double(frame - startFrame) / sampleRate
                let envelope = exp(-3.4 * time) * min(1, time / 0.012)
                let wave = sin(2 * .pi * frequency * time)
                    + 0.38 * sin(2 * .pi * frequency * 2 * time)
                    + 0.13 * sin(2 * .pi * frequency * 3 * time)
                let current = Double(samples[frame]) + wave * envelope * amplitude
                samples[frame] = Float(max(-0.95, min(0.95, current)))
            }
        }
    }

    private func frequency(forMidiNote midiNote: Int) -> Double {
        440 * pow(2, Double(midiNote - 69) / 12)
    }
}
