import Combine
import SwiftUI
import AVFoundation
import AudioToolbox

@MainActor
final class MasteryPractice: ObservableObject {
    @Published var remaining: TimeInterval = 300
    @Published private(set) var timerDuration: TimeInterval = 300
    var hasPausedTimer: Bool { !running && remaining > 0 && remaining < timerDuration }
    @Published private(set) var running = false
    @Published private(set) var metronomePlaying = false
    @Published var error: String?
    private var deadline: Date?
    private var started: Date?
    private var elapsed: TimeInterval = 0
    private var ticker: Timer?
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    var onSession: ((TimeInterval) -> Void)?

    func startTimer() {
        guard !running, remaining > 0 else { return }
        started = Date()
        deadline = Date().addingTimeInterval(remaining)
        running = true
        ticker = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func tick() {
        guard let deadline else { return }
        remaining = max(0, deadline.timeIntervalSinceNow)
        if remaining <= 0 {
            finishTimer()
            AudioServicesPlaySystemSound(1007)
        }
    }

    func pauseTimer() {
        if let started {
            let end = min(Date(), deadline ?? Date())
            elapsed += max(0, end.timeIntervalSince(started))
        }
        if let deadline { remaining = max(0, deadline.timeIntervalSinceNow) }
        started = nil
        deadline = nil
        running = false
        ticker?.invalidate()
        ticker = nil
    }

    func finishTimer() {
        pauseTimer()
        if elapsed >= 1 { onSession?(elapsed) }
        elapsed = 0
    }

    func resetTimer(minutes: Int) {
        finishTimer()
        timerDuration = TimeInterval(minutes * 60)
        remaining = timerDuration
    }

    func startMetronome(bpm: Int, beats: Int) {
        stopMetronome()
        let rate = 48_000.0
        let beatFrames = Int(rate * 60 / Double(min(240, max(30, bpm))))
        let beats = min(7, max(1, beats))
        let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(beatFrames * beats)),
              let samples = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = buffer.frameCapacity
        samples.initialize(repeating: 0, count: Int(buffer.frameLength))
        for beat in 0..<beats {
            let frequency = beat == 0 ? 1600.0 : 1000.0
            for frame in 0..<min(beatFrames, 1800) {
                let t = Double(frame) / rate
                samples[beat * beatFrames + frame] = Float(sin(2 * .pi * frequency * t) * exp(-t * 110) * 0.45)
            }
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
            self.engine = engine
            self.player = player
            metronomePlaying = true
        } catch { self.error = L10n.string("mastery.audio.error") }
    }

    func stopMetronome() {
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
        metronomePlaying = false
    }

    func stopAll() { finishTimer(); stopMetronome() }
}
