import SwiftUI

/// The "come back to center" card from Assets/ComeBack.svg (viewBox 280.98 × 151.97),
/// shown full screen after the logo during the opening. The wordmark is the real vector;
/// the three text lines use system faces until the SVG's text is outlined.
struct IntroCard: View {
    var color: Color

    private let vw: CGFloat = 280.98
    private let vh: CGFloat = 151.97

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width * 0.86 / vw, geo.size.height * 0.86 / vh)
            ZStack(alignment: .topLeading) {
                // Wordmark: same shape as the logo, placed where the SVG puts it (x 95.7, y 0).
                LogoShape()
                    .fill(color)
                    .frame(width: 82.25 * s, height: 16.49 * s)
                    .offset(x: 95.7 * s, y: 0)

                // COME BACK ........ TO CENTER  (baseline 58.31, 6.16pt mono)
                HStack(spacing: 0) {
                    Text("COME BACK")
                    Spacer(minLength: 0)
                    Text("TO CENTER")
                }
                .font(.system(size: 6.16 * s, design: .monospaced))
                .frame(width: vw * s)
                .offset(y: (58.31 - 6.16 * 0.8) * s)

                // between (baseline 127.76, 12pt bold grotesk)
                Text("between")
                    .font(.custom("HelveticaNeue-Bold", size: 12 * s))
                    .tracking(-0.42 * s)
                    .offset(x: 33.09 * s, y: (127.76 - 12 * 0.8) * s)

                // BETWEEN (baseline 148.68, 12pt mono)
                Text("BETWEEN")
                    .font(.system(size: 12 * s, design: .monospaced))
                    .offset(x: 21.79 * s, y: (148.68 - 12 * 0.8) * s)
            }
            .foregroundStyle(color)
            .frame(width: vw * s, height: vh * s, alignment: .topLeading)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
