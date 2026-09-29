import SwiftUI
import AppKit

/// Opens the session window: a borderless window over everything (full screen),
/// or a floating window if full screen is turned off. Esc ends, Space pauses.
final class SessionPresenter: NSObject, NSWindowDelegate {
    static let shared = SessionPresenter()

    private var window: NSWindow?
    private var clock: SessionClock?
    private var keyMonitor: Any?

    func start(_ sequence: BreathSequence) {
        close()

        let clock = SessionClock(sequence: sequence)
        self.clock = clock
        let root = SessionView(clock: clock, onClose: { [weak self] in self?.close() })

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let fullScreen = UserDefaults.standard.object(forKey: "fullScreen") as? Bool ?? true
        let w: NSWindow
        if fullScreen {
            w = KeyableWindow(contentRect: screen.frame, styleMask: [.borderless],
                              backing: .buffered, defer: false)
            w.level = .screenSaver
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            let size = NSSize(width: 960, height: 640)
            let origin = NSPoint(x: screen.visibleFrame.midX - size.width / 2,
                                 y: screen.visibleFrame.midY - size.height / 2)
            w = KeyableWindow(contentRect: NSRect(origin: origin, size: size),
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.level = .floating
        }
        w.isReleasedWhenClosed = false
        w.backgroundColor = .black
        w.appearance = NSAppearance(named: .darkAqua)
        w.contentView = NSHostingView(rootView: root)
        w.delegate = self
        w.alphaValue = 0

        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.6
            w.animator().alphaValue = 1
        }
        window = w

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            switch event.keyCode {
            case 53: self?.close(); return nil               // Esc
            case 49: self?.clock?.togglePause(); return nil  // Space
            default: return event
            }
        }
    }

    func close() {
        cleanUp()
        guard let w = window else { return }
        window = nil
        w.delegate = nil
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.4
            w.animator().alphaValue = 0
        }, completionHandler: {
            w.orderOut(nil)
        })
    }

    // User closed the windowed version with the red button.
    func windowWillClose(_ notification: Notification) {
        cleanUp()
        window = nil
    }

    private func cleanUp() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        clock?.stop()
        clock = nil
    }
}

final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
