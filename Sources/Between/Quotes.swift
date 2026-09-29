import Foundation

/// Closing quotes, shown one per finished session in rotation.
/// Public-domain translations only; swap in your own favorites here.
struct Quote {
    let text: String
    let source: String

    static let all: [Quote] = [
        Quote(text: "Who can make the muddy water clear? Let it be still, and it will gradually become clear.",
              source: "Tao Te Ching, 15 · tr. James Legge"),
        Quote(text: "The highest excellence is like that of water.",
              source: "Tao Te Ching, 8 · tr. James Legge"),
        Quote(text: "The journey of a thousand li commenced with a single step.",
              source: "Tao Te Ching, 64 · tr. James Legge"),
        Quote(text: "He who knows other men is discerning; he who knows himself is intelligent.",
              source: "Tao Te Ching, 33 · tr. James Legge"),
        Quote(text: "Nowhere either with more quiet or more freedom from trouble does a man retire than into his own soul.",
              source: "Marcus Aurelius, Meditations · tr. George Long"),
        Quote(text: "All that we are is the result of what we have thought.",
              source: "The Dhammapada · tr. F. Max Müller"),
        Quote(text: "I have never found the companion that was so companionable as solitude.",
              source: "Henry David Thoreau, Walden"),
        Quote(text: "I loafe and invite my soul.",
              source: "Walt Whitman, Song of Myself"),
    ]

    /// The next quote in the rotation; remembers its place between launches.
    static func next() -> Quote {
        let d = UserDefaults.standard
        let i = d.integer(forKey: "quoteIndex") % all.count
        d.set(i + 1, forKey: "quoteIndex")
        return all[i]
    }
}
