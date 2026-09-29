import SwiftUI

/// Full-screen ambient scene: the painted scene, softened with a blur, with living film grain on top.
struct AmbientView: View {
    let scene: SceneKind
    let level: Double      // breath, 0…1
    let time: Double       // seconds, drives the slow drift
    let drift: Bool

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                scene.paint(&ctx, size: size, t: drift ? time : 0, b: level)
            }
            .drawingGroup()
            .blur(radius: 26, opaque: true)

            Canvas { ctx, size in
                // Shift the noise every ~90ms so the grain feels alive, like film.
                let frame = Int(time * 11)
                var r = UInt64(truncatingIfNeeded: frame &* 2_654_435_761)
                r = r &* 6364136223846793005 &+ 1442695040888963407
                let ox = -Double(r % 128)
                let oy = -Double((r >> 16) % 128)
                let tile = Grain.image
                var y = oy
                while y < Double(size.height) {
                    var x = ox
                    while x < Double(size.width) {
                        ctx.draw(tile, in: CGRect(x: x, y: y, width: 128, height: 128))
                        x += 128
                    }
                    y += 128
                }
            }
            .blendMode(.overlay)
            .opacity(scene.grain)
            .allowsHitTesting(false)
        }
        .compositingGroup()
    }
}

/// One tile of grayscale noise, made once.
enum Grain {
    static let image: Image = {
        let n = 256
        var bytes = [UInt8](repeating: 0, count: n * n)
        var s: UInt64 = 0x9E3779B97F4A7C15
        for i in 0..<bytes.count {
            s = s &* 6364136223846793005 &+ 1442695040888963407
            bytes[i] = UInt8(truncatingIfNeeded: s >> 56)
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        let cg = CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: n,
                         space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                         provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        return Image(decorative: cg, scale: 2)
    }()
}
