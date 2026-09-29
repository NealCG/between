import AppKit

/// The menu bar icon: a circle with 8 spokes and a small center dot, drawn as a template
/// image so macOS tints it for light and dark menu bars.
enum MenuIcon {
    static let image: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { rect in
            let c = NSPoint(x: rect.midX, y: rect.midY)
            let r: CGFloat = 7.4
            NSColor.black.setStroke()
            NSColor.black.setFill()

            let ring = NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ring.lineWidth = 1
            ring.stroke()

            let spokes = NSBezierPath()
            spokes.lineWidth = 1
            spokes.lineCapStyle = .round
            for k in 0..<8 {
                let a = CGFloat(k) * .pi / 4
                spokes.move(to: c)
                spokes.line(to: NSPoint(x: c.x + (r - 0.2) * cos(a), y: c.y + (r - 0.2) * sin(a)))
            }
            spokes.stroke()

            NSBezierPath(ovalIn: NSRect(x: c.x - 1.5, y: c.y - 1.5, width: 3, height: 3)).fill()
            return true
        }
        img.isTemplate = true
        img.accessibilityDescription = "Between"
        return img
    }()
}
