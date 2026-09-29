import AVFoundation

/// A very soft tone for phase changes: a low sine that swells in over about a second and fades
/// out over about 4s. A few players take turns so tones overlap instead of cutting off.
final class SoftTone {
    static let shared = SoftTone()

    private let engine = AVAudioEngine()
    private let players = (0..<3).map { _ in AVAudioPlayerNode() }
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var buffers: [Double: AVAudioPCMBuffer] = [:]
    private var next = 0
    private var running = false

    private init() {
        for p in players {
            engine.attach(p)
            engine.connect(p, to: engine.mainMixerNode, format: format)
        }
    }

    func play(_ hz: Double) {
        if !running {
            do { try engine.start(); running = true } catch { return }
        }
        let buffer = buffers[hz] ?? makeBuffer(hz)
        buffers[hz] = buffer

        let player = players[next]
        next = (next + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    private func makeBuffer(_ hz: Double) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let length = 5.0
        let frames = AVAudioFrameCount(rate * length)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frames) {
            let t = Double(i) / rate
            let swell = min(1, t / 1.1)
            let envelope = swell * swell * exp(-max(0, t - 1.1) * 1.2)
            // Pure low sine, very quiet.
            data[i] = Float(0.02 * envelope * sin(2 * .pi * hz * t))
        }
        return buffer
    }
}
