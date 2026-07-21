import AVFoundation
import Combine
import Foundation
import OSLog

struct PlaybackChord {
    let rootPitchClass: Int
    let intervals: [Int]
    let durationMultiplier: Double

    init(
        rootPitchClass: Int,
        intervals: [Int],
        durationMultiplier: Double = 1
    ) {
        self.rootPitchClass = rootPitchClass
        self.intervals = intervals
        self.durationMultiplier = durationMultiplier
    }
}

private struct VoicedChord {
    let midiNotes: [Int]
    let durationMultiplier: Double
}

final class ProgressionAudioPlayer: ObservableObject {
    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 48_000
    private let channelCount: AVAudioChannelCount = 2
    private var playbackID = UUID()

    init() {
        let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channelCount
        )
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play(chords: [PlaybackChord], bpm: Double = 120) {
        guard !chords.isEmpty else { return }

        if isPlaying {
            stop()
            return
        }

        let id = UUID()
        playbackID = id
        configureAudioSession()

        let voicedChords = makeVoicedChords(from: chords)
        guard !voicedChords.isEmpty else { return }

        let baseChordDuration = max(0.5, PianoSampleLibrary.shared.sampleDuration / 2 - 1)
        let normalizedBPM = min(max(bpm, 40), 200)
        let chordDuration = baseChordDuration * (120 / normalizedBPM)
        let buffer = makeBuffer(voicedChords: voicedChords, chordDuration: chordDuration)
        let totalDuration = chordDuration * voicedChords.reduce(0) {
            $0 + $1.durationMultiplier
        }

        player.stop()
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                AppLogger.audio.error("Failed to start audio engine: \(error.localizedDescription, privacy: .public)")
                return
            }
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
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredSampleRate(sampleRate)
            try session.setActive(true)
        } catch {
            AppLogger.audio.error("Failed to configure audio session: \(error.localizedDescription, privacy: .public)")
        }
        #endif
    }

    private func makeBuffer(voicedChords: [VoicedChord], chordDuration: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channelCount
        )!
        let frameCount = AVAudioFrameCount(
            (
                voicedChords.reduce(0) { $0 + $1.durationMultiplier }
                    * chordDuration
                    * sampleRate
            ).rounded(.up)
        )
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let outputChannels = buffer.floatChannelData else { return buffer }
        for channel in 0..<Int(channelCount) {
            outputChannels[channel].initialize(repeating: 0, count: Int(frameCount))
        }

        var elapsedDuration: Double = 0
        for voicedChord in voicedChords {
            let midiNotes = voicedChord.midiNotes
            let currentDuration = chordDuration * voicedChord.durationMultiplier
            let startFrame = Int(elapsedDuration * sampleRate)
            let noteGain = Float(0.74 / sqrt(Double(max(midiNotes.count, 1))))

            for midiNote in midiNotes {
                if let sample = PianoSampleLibrary.shared.sample(for: midiNote) {
                    mix(
                        sample: sample,
                        into: outputChannels,
                        outputFrameCount: Int(frameCount),
                        startFrame: startFrame,
                        maximumFrameCount: Int(currentDuration * sampleRate),
                        gain: noteGain
                    )
                } else {
                    renderFallbackNote(
                        midiNote: midiNote,
                        startFrame: startFrame,
                        duration: currentDuration,
                        gain: noteGain,
                        into: outputChannels,
                        frameCount: Int(frameCount)
                    )
                }
            }
            elapsedDuration += currentDuration
        }

        softLimit(outputChannels, frameCount: Int(frameCount))
        return buffer
    }

    private func mix(
        sample: AVAudioPCMBuffer,
        into outputChannels: UnsafePointer<UnsafeMutablePointer<Float>>,
        outputFrameCount: Int,
        startFrame: Int,
        maximumFrameCount: Int,
        gain: Float
    ) {
        guard let sampleChannels = sample.floatChannelData else { return }
        let framesToCopy = min(
            Int(sample.frameLength),
            outputFrameCount - startFrame,
            maximumFrameCount
        )
        guard framesToCopy > 0 else { return }
        let fadeFrameCount = min(Int(sampleRate * 0.18), framesToCopy)
        let fadeStartFrame = framesToCopy - fadeFrameCount

        for channel in 0..<Int(channelCount) {
            let sourceChannel = min(channel, Int(sample.format.channelCount) - 1)
            guard sourceChannel >= 0 else { continue }
            let source = sampleChannels[sourceChannel]
            let destination = outputChannels[channel]

            for frame in 0..<framesToCopy {
                let fadeGain: Float
                if frame >= fadeStartFrame {
                    fadeGain = Float(framesToCopy - frame) / Float(max(fadeFrameCount, 1))
                } else {
                    fadeGain = 1
                }
                destination[startFrame + frame] += source[frame] * gain * fadeGain
            }
        }
    }

    private func softLimit(
        _ channels: UnsafePointer<UnsafeMutablePointer<Float>>,
        frameCount: Int
    ) {
        for channel in 0..<Int(channelCount) {
            for frame in 0..<frameCount {
                channels[channel][frame] = tanh(channels[channel][frame])
            }
        }
    }

    private func makeVoicedChords(from chords: [PlaybackChord]) -> [VoicedChord] {
        var result: [VoicedChord] = []

        for chord in chords {
            let candidates = voicingCandidates(for: chord)
            guard !candidates.isEmpty else { continue }

            let selected: [Int]
            if let previous = result.last?.midiNotes {
                selected = candidates.min {
                    score(candidate: $0, after: previous) < score(candidate: $1, after: previous)
                } ?? candidates[0]
            } else {
                selected = candidates.min {
                    openingScore($0) < openingScore($1)
                } ?? candidates[0]
            }
            result.append(
                VoicedChord(
                    midiNotes: selected,
                    durationMultiplier: max(0.25, chord.durationMultiplier)
                )
            )
        }

        return result
    }

    private func voicingCandidates(for chord: PlaybackChord) -> [[Int]] {
        let pitchClasses = uniquePitchClasses(for: chord)
        let choices = pitchClasses.map { pitchClass in
            stride(from: 36, through: 59, by: 1).filter { $0 % 12 == pitchClass }
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
        abs(average(candidate) - 49) + span(candidate) * 0.12
    }

    private func score(candidate: [Int], after previous: [Int]) -> Double {
        let movementToPrevious = candidate.reduce(0) { total, note in
            total + (previous.map { abs(note - $0) }.min() ?? 0)
        }
        let movementFromPrevious = previous.reduce(0) { total, note in
            total + (candidate.map { abs(note - $0) }.min() ?? 0)
        }
        let movement = Double(movementToPrevious + movementFromPrevious) / 2
        let averageShift = abs(average(candidate) - average(previous))
        return movement + averageShift * 0.8 + span(candidate) * 0.08
    }

    private func average(_ notes: [Int]) -> Double {
        guard !notes.isEmpty else { return 0 }
        return Double(notes.reduce(0, +)) / Double(notes.count)
    }

    private func span(_ notes: [Int]) -> Double {
        guard let first = notes.first, let last = notes.last else { return 0 }
        return Double(last - first)
    }

    private func renderFallbackNote(
        midiNote: Int,
        startFrame: Int,
        duration: Double,
        gain: Float,
        into channels: UnsafePointer<UnsafeMutablePointer<Float>>,
        frameCount: Int
    ) {
        let endFrame = min(frameCount, startFrame + Int(duration * sampleRate))
        guard startFrame < endFrame else { return }
        let frequency = 440 * pow(2, Double(midiNote - 69) / 12)

        for frame in startFrame..<endFrame {
            let time = Double(frame - startFrame) / sampleRate
            let envelope = exp(-0.72 * time) * min(1, time / 0.012)
            let wave = sin(2 * .pi * frequency * time)
                + 0.32 * sin(2 * .pi * frequency * 2 * time)
                + 0.11 * sin(2 * .pi * frequency * 3 * time)
            let value = Float(wave * envelope) * gain * 0.45
            for channel in 0..<Int(channelCount) {
                channels[channel][frame] += value
            }
        }
    }
}

private final class PianoSampleLibrary {
    static let shared = PianoSampleLibrary()

    private let sampleNames = ["C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B"]
    private var samples: [Int: AVAudioPCMBuffer] = [:]
    private var cachedSampleDuration: Double?

    var sampleDuration: Double {
        if let cachedSampleDuration {
            return cachedSampleDuration
        }
        _ = sample(for: 36)
        return cachedSampleDuration ?? 6
    }

    func sample(for midiNote: Int) -> AVAudioPCMBuffer? {
        if let sample = samples[midiNote] {
            return sample
        }
        guard (36...59).contains(midiNote), let url = sampleURL(for: midiNote) else {
            return nil
        }

        do {
            let file = try AVAudioFile(forReading: url)
            let frameCount = AVAudioFrameCount(file.length)
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: frameCount
            ) else {
                return nil
            }
            try file.read(into: buffer)
            samples[midiNote] = buffer
            cachedSampleDuration = Double(buffer.frameLength) / buffer.format.sampleRate
            return buffer
        } catch {
            return nil
        }
    }

    private func sampleURL(for midiNote: Int) -> URL? {
        let pitchClass = (midiNote % 12 + 12) % 12
        let octave = midiNote / 12 - 1
        let name = "\(sampleNames[pitchClass])\(octave)"

        return Bundle.main.url(
            forResource: name,
            withExtension: "wav",
            subdirectory: "PianoSamples"
        ) ?? Bundle.main.url(forResource: name, withExtension: "wav")
    }
}
