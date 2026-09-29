import SwiftUI
import AppKit

struct SessionView: View {
    @ObservedObject var clock: SessionClock
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chrome = true
    @State private var idleWork: DispatchWorkItem?

    private var ink: Color { clock.sequence.scene.ink }

    var body: some View {
        TimelineView(.animation) { timeline in
            let seq = clock.sequence
            let t = clock.elapsed(at: timeline.date)
            let frame = clock.finished ? nil : seq.frame(at: t)
            // Opening: the logo fades in on black, holds, fades out; then the scene rises from the dark.
            let splash = BreathSequence.splash
            let logo = clock.finished ? 0 : clamp01(t / 0.8) * clamp01((splash - 0.1 - t) / 0.8)
            let veil = clock.finished ? 0 : clamp01(1 - (t - (splash - 0.5)) / 1.5)

            ZStack {
                AmbientView(scene: seq.scene,
                            level: frame?.level ?? restLevel(t, seq),
                            time: t,
                            drift: !reduceMotion)

                if clock.finished { doneView(seq) }
            }
            .overlay(alignment: .top) {
                // Small wordmark at top center, once the scene is up.
                LogoShape()
                    .fill(ink)
                    .frame(width: 74, height: 74 / LogoShape.aspect)
                    .padding(.top, 28)
                    .opacity(1 - veil)
            }
            .overlay(alignment: .topLeading) { header(seq).opacity(chrome ? 1 : 0) }
            .overlay(alignment: .topTrailing) {
                if !clock.finished { controls.opacity(chrome || clock.isPaused ? 1 : 0) }
            }
            .overlay(alignment: .bottomLeading) {
                if let f = frame { cue(f) }
            }
            .overlay(alignment: .bottomTrailing) { timerView(t: t, seq: seq) }
            .overlay {
                ZStack {
                    Color(red: 3 / 255, green: 4 / 255, blue: 4 / 255).opacity(veil)
                    LogoShape()
                        .fill(Color(red: 244 / 255, green: 243 / 255, blue: 236 / 255))
                        .frame(width: 220, height: 220 / LogoShape.aspect)
                        .opacity(logo)
                }
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topTrailing) {
                // Keep Pause / End reachable above the opening.
                if veil > 0 && !clock.finished { controls.opacity(chrome ? 1 : 0) }
            }
        }
        .tracking(textTracking)
        .foregroundStyle(ink)
        .background(Color(red: 2 / 255, green: 3 / 255, blue: 3 / 255))
        .ignoresSafeArea()
        .onContinuousHover { _ in poke() }
        .onAppear { poke() }
        .animation(.easeInOut(duration: 0.6), value: chrome)
    }

    private func header(_ seq: BreathSequence) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(seq.name).font(helvetica(15))
            Text(seq.tag).font(helvetica(12.5)).foregroundStyle(ink.opacity(0.45))
        }
        .padding(.leading, 28).padding(.top, 26)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button(clock.isPaused ? "Resume" : "Pause") { clock.togglePause() }
            Button("End", action: onClose)
        }
        .buttonStyle(PillButton(ink: ink))
        .padding(.trailing, 22).padding(.top, 22)
    }

    /// The breathing prompt, bottom left.
    private func cue(_ f: BreathFrame) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(f.label)
                .font(helvetica(34))
                .opacity(clock.isPaused ? 0.35 : 1)
                .animation(.easeInOut(duration: 0.8), value: f.label)
            Text(clock.isPaused ? "PAUSED" : f.count.map { "\($0)" } ?? " ")
                .font(helvetica(clock.isPaused ? 14 : 76))
                .monospacedDigit()
        }
        .shadow(color: clock.sequence.scene.inkIsDark ? Color.white.opacity(0.35) : Color.black.opacity(0.3), radius: 14)
        .padding(.leading, 28).padding(.bottom, 26)
    }

    private func timerView(t: Double, seq: BreathSequence) -> some View {
        let left = clock.finished ? 0 : min(seq.total, seq.total - (t - BreathSequence.intro))
        return Text(formatTime(left))
            .font(helvetica(15))
            .monospacedDigit()
            .foregroundStyle(ink.opacity(0.62))
            .padding(.trailing, 28).padding(.bottom, 24)
    }

    private func doneView(_ seq: BreathSequence) -> some View {
        VStack(spacing: 18) {
            if let quote = clock.quote {
                Text("“\(quote.text)”")
                    .font(helvetica(34))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 620)
                Text(quote.source)
                    .font(helvetica(13))
                    .foregroundStyle(ink.opacity(0.62))
            }
            Text("\(seq.name) · \(formatTime(seq.total)) of breathing")
                .font(helvetica(12))
                .foregroundStyle(ink.opacity(0.36))
                .padding(.top, 10)
            Button("Back to work", action: onClose).buttonStyle(PillButton(ink: ink))
        }
        .padding(.horizontal, 32)
        .transition(.opacity.animation(.easeIn(duration: 2)))
    }

    /// Breath level while settling after the session ends: rises gently to a calm resting state.
    private func restLevel(_ t: Double, _ seq: BreathSequence) -> Double {
        let since = max(0, t - BreathSequence.intro - seq.total)
        let p = min(1, since / 4)
        return 0.35 * (0.5 - 0.5 * cos(Double.pi * p))
    }

    private func clamp01(_ v: Double) -> Double { max(0, min(1, v)) }

    private func poke() {
        if !chrome { chrome = true }
        idleWork?.cancel()
        let work = DispatchWorkItem {
            guard !clock.isPaused, !clock.finished else { return }
            chrome = false
            NSCursor.setHiddenUntilMouseMoves(true)
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8, execute: work)
    }
}

struct PillButton: ButtonStyle {
    var ink: Color = .white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(helvetica(13))
            .foregroundStyle(ink.opacity(configuration.isPressed ? 1 : 0.75))
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(Capsule().fill(ink.opacity(configuration.isPressed ? 0.16 : 0.08)))
            .overlay(Capsule().strokeBorder(ink.opacity(0.14)))
            .contentShape(Capsule())
    }
}
