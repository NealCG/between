import SwiftUI

/// The three ambient scenes, after the reference images: meadow in motion (blurred wildflowers and a light beam),
/// tide (teal and cornflower blue with pale curling forms and a sun-glow) and dusk (periwinkle to lavender).
/// Each one also carries the breath: `b` runs 0 (empty) to 1 (full).
enum SceneKind {
    case meadow, tide, dusk

    /// Text color. All three scenes are mid-dark, so light text reads on each.
    var ink: Color { Color(red: 244 / 255, green: 243 / 255, blue: 236 / 255) }
    var inkIsDark: Bool { false }

    /// Film grain strength, kept light.
    var grain: Double {
        switch self {
        case .meadow: return 0.06
        case .tide: return 0.06
        case .dusk: return 0.08
        }
    }

    /// Small preview for the menu.
    var swatch: LinearGradient {
        switch self {
        case .meadow:
            return LinearGradient(colors: [rgb((244, 246, 242)), rgb((217, 194, 76)), rgb((169, 189, 212)), rgb((127, 154, 72))],
                                  startPoint: .topTrailing, endPoint: .bottomLeading)
        case .tide:
            return LinearGradient(colors: [rgb((63, 120, 200)), rgb((207, 224, 228)), rgb((58, 112, 120))],
                                  startPoint: .leading, endPoint: .trailing)
        case .dusk:
            return LinearGradient(colors: [rgb((77, 81, 144)), rgb((127, 124, 178)), rgb((152, 135, 166))],
                                  startPoint: .top, endPoint: .bottom)
        }
    }

    func paint(_ ctx: inout GraphicsContext, size: CGSize, t: Double, b: Double) {
        switch self {
        case .meadow: paintMeadow(&ctx, size, t, b)
        case .tide: paintTide(&ctx, size, t, b)
        case .dusk: paintDusk(&ctx, size, t, b)
        }
    }
}

// MARK: - Scenes

/// Meadow in motion: a wildflower field blurred by movement (yellow, lime, pale blue, the odd
/// orange fleck), long soft sweeps of green and cream, a beam of light from the top right,
/// and cream cloud reflections on teal water.
/// Breathing in, the light floods in and the field brightens and rushes; breathing out, it settles.
private func paintMeadow(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, _ b: Double) {
    let W = Double(size.width), H = Double(size.height)
    let full = Path(CGRect(origin: .zero, size: size))
    ctx.fill(full, with: .linearGradient(
        Gradient(stops: [.init(color: rgb((125, 143, 69)), location: 0),
                         .init(color: rgb((134, 160, 78)), location: 0.45),
                         .init(color: rgb((85, 127, 63)), location: 0.75),
                         .init(color: rgb((47, 90, 44)), location: 1)]),
        startPoint: .zero, endPoint: CGPoint(x: W, y: H)))

    let ang = -0.6                                  // direction of motion, rising to the right
    let slope = tan(ang)
    blob(ctx, W * 0.9, H * 0.42, W * (0.3 + 0.1 * b), H * (0.32 + 0.1 * b), (150, 182, 210), 0.4 + 0.2 * b)     // sky blue, right
    blob(ctx, W * 0.48, H * 0.7, W * (0.22 + 0.12 * b), H * (0.3 + 0.14 * b), (214, 214, 96), 0.26 + 0.3 * b)   // yellow glow

    for s in meadowSweeps {
        let run = wrap(s.x + t * 0.006 * s.v, -0.4, 1.4)
        blob(ctx, run * W, s.y * H - (run - 0.5) * W * 0.48, s.w * W, s.h * H * (0.9 + 0.4 * b),
             s.cream ? (226, 230, 196) : (196, 204, 110), 0.16 + 0.2 * b, rotation: -0.45)
    }

    let rush = 0.012 + 0.01 * b
    for f in meadowFlecks {
        let along = wrap(f.x + t * rush * f.v, -0.2, 1.2)
        let px = along * W
        let py = wrap(f.y * H + px * slope, -H * 0.1, H * 1.1)          // travel along the slant
        blob(ctx, px, py, f.l * W * (0.8 + 0.5 * b), f.h * H, f.col, f.a * (0.2 + 0.34 * b), rotation: ang)
    }

    // From the water image: teal-blue water and cream cloud reflections drifting.
    blob(ctx, W * 0.72, H * 0.62, W * 0.42, H * 0.34, (96, 150, 156), 0.34 + 0.12 * b)                       // teal water
    let clouds: [(Double, Double, Double, Double)] = [(0.2, 0.5, 0.24, 0.24), (0.6, 0.16, 0.18, 0.13), (0.88, 0.34, 0.13, 0.11)]
    for (i, c) in clouds.enumerated() {
        let cx = W * (c.0 + 0.02 * sin(t * 0.08 + Double(i) * 2))
        let k = 0.9 + 0.25 * b
        blob(ctx, cx, H * c.1, W * c.2 * k, H * c.3 * k, (238, 234, 206), 0.24 + 0.34 * b)
    }
    blob(ctx, W * 0.9, H * 1.02, W * 0.4, H * 0.3, (40, 82, 38), 0.35)                                        // deep green corner
    blob(ctx, W * 0.46, H * 0.28, W * (0.5 + 0.22 * b), H * (0.06 + 0.12 * b), (240, 246, 236), 0.12 + 0.46 * b,
         rotation: -0.72)                                                                                       // the beam
    blob(ctx, W * 0.74, -H * 0.02, W * (0.18 + 0.1 * b), H * (0.16 + 0.12 * b), (250, 252, 250), 0.22 + 0.5 * b) // hot spot
    ctx.fill(full, with: .color(rgb((20, 34, 20), 0.16 * (1 - b))))                                            // dims on the exhale
}

/// Tide and sky: deep teal and cornflower blue, pale cloud-like forms that slowly curl around
/// each other, and a soft sun-glow. Breathing in, the pale forms swell and the glow opens up;
/// the holds keep a slow drift so the screen never goes still.
private func paintTide(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, _ b: Double) {
    let W = Double(size.width), H = Double(size.height)
    let full = Path(CGRect(origin: .zero, size: size))
    ctx.fill(full, with: .linearGradient(
        Gradient(stops: [.init(color: rgb((47, 95, 150)), location: 0),
                         .init(color: rgb((58, 111, 134)), location: 0.45),
                         .init(color: rgb((47, 100, 112)), location: 1)]),
        startPoint: .zero, endPoint: CGPoint(x: W, y: H)))

    blob(ctx, W * 0.02, H * 0.12, W * 0.3, H * 0.34, (60, 118, 206), 0.6)          // cornflower, top left
    blob(ctx, W * 1.0, H * 0.84, W * 0.32, H * 0.36, (66, 124, 204), 0.5)          // cornflower, lower right

    for (i, x) in [0.22, 0.84].enumerated() {                                        // faint vertical bands
        let w = W * (0.04 + 0.05 * b)
        let cx = x * W + sin(t * 0.05 + Double(i)) * W * 0.01
        ctx.fill(Path(CGRect(x: cx - w, y: 0, width: w * 2, height: H)), with: .linearGradient(
            Gradient(stops: [.init(color: rgb((130, 176, 196), 0), location: 0),
                             .init(color: rgb((130, 176, 196), 0.16), location: 0.5),
                             .init(color: rgb((130, 176, 196), 0), location: 1)]),
            startPoint: CGPoint(x: cx - w, y: 0), endPoint: CGPoint(x: cx + w, y: 0)))
    }

    for f in tideForms {                                                             // pale forms curling around the center
        let a = f.a + t * 0.035 * f.dir
        let x = W * (0.5 + cos(a) * f.r * 0.9)
        let y = H * (0.5 + sin(a) * f.r)
        let k = 0.85 + 0.35 * b
        blob(ctx, x, y, W * f.w * k, H * f.h * k, (206, 224, 228), (0.26 + 0.34 * b) * f.k, rotation: a * 0.6)
    }

    let d = hypot(W, H)
    let glow = CGPoint(x: W * (0.62 + 0.02 * sin(t * 0.07)), y: H * 0.56)
    ctx.fill(full, with: .radialGradient(
        Gradient(stops: [.init(color: rgb((232, 238, 206), 0.3 + 0.3 * b), location: 0),
                         .init(color: rgb((176, 208, 200), 0.14 + 0.16 * b), location: 0.4),
                         .init(color: rgb((90, 140, 146), 0), location: 1)]),
        center: glow, startRadius: 0, endRadius: d * (0.2 + 0.2 * b)))
    ctx.fill(full, with: .color(rgb((16, 34, 52), 0.16 * (1 - b))))              // dims on the exhale
}

/// Periwinkle above, lavender below. The horizon rises and a lavender glow swells as you
/// breathe in; a slow undercurrent keeps it gently pulsing through the holds.
private func paintDusk(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, _ b: Double) {
    let W = Double(size.width), H = Double(size.height)
    let full = Path(CGRect(origin: .zero, size: size))
    let pulse = 0.5 + 0.5 * sin(t * 1.05)                  // ~6s undercurrent
    let hz = 0.82 - 0.36 * b
    let s1 = max(0.16, hz - 0.45)
    let s2 = min(0.98, max(s1 + 0.08, hz))
    ctx.fill(full, with: .linearGradient(
        Gradient(stops: [.init(color: rgb((72, 76, 136)), location: 0),
                         .init(color: rgb((106, 105, 164)), location: s1),
                         .init(color: rgb((142, 130, 174)), location: s2),
                         .init(color: rgb((152, 135, 166)), location: 1)]),
        startPoint: .zero, endPoint: CGPoint(x: 0, y: H)))

    blob(ctx, W * 0.5, H * hz, W * (0.6 + 0.2 * b), H * (0.22 + 0.2 * b),
         (222, 200, 232), 0.14 + 0.34 * b + 0.07 * pulse)                                   // horizon glow

    for s in duskClouds {
        let x = wrap(s.x * W + t * W * 0.004 * s.v, -W * 0.4, W * 1.4)
        let k = 0.9 + 0.22 * b + 0.04 * pulse
        let col: RGB = s.pale ? (202, 200, 232) : (74, 78, 136)
        blob(ctx, x, s.y * H * (0.7 + 0.5 * hz), s.w * W * k, s.h * H * k, col, s.pale ? 0.16 + 0.24 * b : 0.3)
    }

    ctx.fill(full, with: .linearGradient(
        Gradient(stops: [.init(color: rgb((36, 38, 84), 0.26 * (1 - b) + 0.04 * (1 - pulse)), location: 0),
                         .init(color: rgb((36, 38, 84), 0), location: 1)]),
        startPoint: .zero, endPoint: CGPoint(x: 0, y: H * 0.6)))
}

// MARK: - Helpers

typealias RGB = (Double, Double, Double)

func rgb(_ c: RGB, _ a: Double = 1) -> Color {
    Color(red: c.0 / 255, green: c.1 / 255, blue: c.2 / 255).opacity(a)
}

private func wrap(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
    let span = hi - lo
    return lo + ((v - lo).truncatingRemainder(dividingBy: span) + span).truncatingRemainder(dividingBy: span)
}

/// A soft elliptical glow, optionally rotated (radians).
private func blob(_ ctx: GraphicsContext, _ x: Double, _ y: Double, _ rx: Double, _ ry: Double,
                  _ col: RGB, _ a: Double, rotation: Double = 0) {
    guard ry > 0 else { return }
    var g = ctx
    g.translateBy(x: x, y: y)
    if rotation != 0 { g.rotate(by: .radians(rotation)) }
    g.scaleBy(x: rx / ry, y: 1)
    let gradient = Gradient(stops: [.init(color: rgb(col, a), location: 0),
                                    .init(color: rgb(col, a * 0.55), location: 0.55),
                                    .init(color: rgb(col, 0), location: 1)])
    g.fill(Path(ellipseIn: CGRect(x: -ry, y: -ry, width: ry * 2, height: ry * 2)),
           with: .radialGradient(gradient, center: .zero, startRadius: 0, endRadius: ry))
}

/// Seeded random so each scene's layout is the same every session.
private struct Seeded {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }
}

private struct Cloud { let x, y, w, h, v: Double; let pale: Bool }
private struct Fleck { let x, y, l, h, v, a: Double; let col: RGB }
private struct Sweep { let x, y, w, h, v: Double; let cream: Bool }
private struct Form { let a, r, w, h, k, dir: Double }

private let tideForms: [Form] = {
    var r = Seeded(state: 29)
    return (0..<5).map { i in
        Form(a: Double(i) * 1.26 + r.next(), r: 0.18 + r.next() * 0.2, w: 0.16 + r.next() * 0.12,
             h: 0.14 + r.next() * 0.12, k: 0.7 + r.next() * 0.3, dir: i % 2 == 1 ? -1 : 1)
    }
}()

private let fleckColors: [RGB] = [(238, 212, 64), (200, 214, 78), (176, 196, 222), (238, 238, 212), (214, 126, 74)]

private let meadowFlecks: [Fleck] = {
    var r = Seeded(state: 11)
    return (0..<150).map { _ in
        let k = r.next()
        let col = fleckColors[k < 0.34 ? 0 : k < 0.58 ? 1 : k < 0.84 ? 2 : k < 0.95 ? 3 : 4]
        return Fleck(x: r.next(), y: r.next(), l: 0.035 + r.next() * 0.06, h: 0.016 + r.next() * 0.02,
                     v: 0.6 + r.next() * 0.8, a: 0.5 + r.next() * 0.5, col: col)
    }
}()

private let meadowSweeps: [Sweep] = {
    var r = Seeded(state: 13)
    return (0..<6).map { i in
        Sweep(x: r.next(), y: r.next(), w: 0.4 + r.next() * 0.3, h: 0.06 + r.next() * 0.05, v: 0.4 + r.next() * 0.4, cream: i % 2 == 1)
    }
}()

private let duskClouds: [Cloud] = {
    var r = Seeded(state: 3)
    return (0..<7).map { _ in
        Cloud(x: r.next(), y: 0.04 + r.next() * 0.5, w: 0.2 + r.next() * 0.3, h: 0.07 + r.next() * 0.08,
              v: 0.4 + r.next() * 0.6, pale: r.next() > 0.45)
    }
}()
