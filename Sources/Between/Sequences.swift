import SwiftUI

/// One step of a breath. `target` is how full the orb is at the end of the step (0 = empty, 1 = full).
struct Phase {
    let label: String
    let seconds: Double
    let target: Double
}

struct BreathSequence: Identifiable {
    let id: String
    let name: String
    let tag: String
    let use: String
    let minutes: Double
    let phases: [Phase]
    let scene: SceneKind

    static let splash: Double = 3.5          // the logo on a dark screen, to get your bearings
    static let intro: Double = splash + 3    // then a 3-2-1 countdown before the first breath

    var cycle: Double { phases.reduce(0) { $0 + $1.seconds } }
    var cycles: Int { max(1, Int((minutes * 60 / cycle).rounded())) }
    var total: Double { Double(cycles) * cycle }
}

extension BreathSequence {
    static let all: [BreathSequence] = [
        BreathSequence(
            id: "reset", name: "Reset", tag: "Double inhale, slow sigh out", use: "Between back-to-backs", minutes: 1.5,
            phases: [
                Phase(label: "Breathe in deeply", seconds: 4, target: 0.78),
                Phase(label: "Sip in a little more", seconds: 2, target: 1),
                Phase(label: "Slow sigh out", seconds: 9, target: 0),
            ],
            scene: .meadow),
        BreathSequence(
            id: "focus", name: "Focus", tag: "Box breathing · 5-5-5-5", use: "Before deep work or a meeting", minutes: 3,
            phases: [
                Phase(label: "Breathe in", seconds: 5, target: 1),
                Phase(label: "Hold", seconds: 5, target: 1),
                Phase(label: "Breathe out", seconds: 5, target: 0),
                Phase(label: "Hold", seconds: 5, target: 0),
            ],
            scene: .tide),
        BreathSequence(
            id: "wind", name: "Wind Down", tag: "Long exhale · 5-7-9", use: "End of the day", minutes: 3,
            phases: [
                Phase(label: "Breathe in", seconds: 5, target: 1),
                Phase(label: "Hold", seconds: 7, target: 1),
                Phase(label: "Breathe out slowly", seconds: 9, target: 0),
            ],
            scene: .dusk),
    ]
}

struct BreathFrame {
    var level: Double
    var label: String
    var count: Int?         // nil while settling in
    var phaseProgress: Double?
    var phaseKey: Int
    var toneHz: Double?     // soft tone for this phase; nil during "Settle in"
}

extension BreathSequence {
    /// Where the breath is `t` seconds into the session (intro included). nil once the session is over.
    func frame(at t: Double) -> BreathFrame? {
        let intro = Self.intro
        if t < Self.splash {
            return BreathFrame(level: 0.1, label: "",
                               count: nil, phaseProgress: nil, phaseKey: -2, toneHz: nil)
        }
        if t < intro {
            return BreathFrame(level: 0.1 + 0.04 * sin(t * 1.4), label: "Begin in",
                               count: Int(ceil(intro - t)), phaseProgress: nil, phaseKey: -1, toneHz: nil)
        }
        let x = t - intro
        guard x < total else { return nil }

        var pos = x.truncatingRemainder(dividingBy: cycle)
        var i = 0
        while i < phases.count - 1 && pos >= phases[i].seconds {
            pos -= phases[i].seconds
            i += 1
        }
        let phase = phases[i]
        let from = phases[(i + phases.count - 1) % phases.count].target
        let p = min(1, pos / phase.seconds)
        let eased = 0.5 - 0.5 * cos(Double.pi * p)
        var level = from + (phase.target - from) * eased
        if phase.target == from { level += 0.006 * sin(x * 1.4) }   // barely-there shimmer on holds

        return BreathFrame(level: level, label: phase.label, count: Int(ceil(phase.seconds - pos)),
                           phaseProgress: p, phaseKey: Int(x / cycle) * 100 + i,
                           toneHz: phase.target == from ? 196 : (phase.target > from ? 220 : 165))
    }
}
