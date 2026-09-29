import Foundation
import AppKit

/// Keeps time for one session, including pauses. The view reads `elapsed(at:)` every frame.
final class SessionClock: ObservableObject {
    let sequence: BreathSequence
    @Published private(set) var isPaused = false
    @Published private(set) var finished = false
    @Published private(set) var quote: Quote?

    private let start = Date()
    private var pausedTotal: TimeInterval = 0
    private var pausedAt: Date?
    private var timer: Timer?
    private var lastPhaseKey = Int.min

    init(sequence: BreathSequence) {
        self.sequence = sequence
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func elapsed(at now: Date = Date()) -> Double {
        let pausing = pausedAt.map { now.timeIntervalSince($0) } ?? 0
        return now.timeIntervalSince(start) - pausedTotal - pausing
    }

    func togglePause() {
        guard !finished else { return }
        if let p = pausedAt {
            pausedTotal += Date().timeIntervalSince(p)
            pausedAt = nil
            isPaused = false
        } else {
            pausedAt = Date()
            isPaused = true
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let t = elapsed()
        if t >= BreathSequence.intro + sequence.total {
            quote = Quote.next()
            finished = true
            stop()
            SessionLog.record(seconds: sequence.total)
            return
        }
        if let f = sequence.frame(at: t), f.phaseKey != lastPhaseKey {
            lastPhaseKey = f.phaseKey
            if let hz = f.toneHz, UserDefaults.standard.bool(forKey: "chime") {
                SoftTone.shared.play(hz)
            }
        }
    }
}

enum SessionLog {
    static func record(seconds: Double) {
        let d = UserDefaults.standard
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        if d.string(forKey: "logDay") != today {
            d.set(today, forKey: "logDay")
            d.set(0, forKey: "logCount")
            d.set(0.0, forKey: "logSeconds")
        }
        d.set(d.integer(forKey: "logCount") + 1, forKey: "logCount")
        d.set(d.double(forKey: "logSeconds") + seconds, forKey: "logSeconds")
    }
}
